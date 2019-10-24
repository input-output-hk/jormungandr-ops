{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DeriveGeneric #-}

module Main (main) where

import System.Environment (getArgs)
import Turtle
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Data.Ix
import Data.Aeson
import GHC.Generics
import qualified Data.HashMap.Strict as HM
import qualified Data.Vector as V
import qualified Data.ByteString.Lazy as LBS

data Flag1 = NormalKey | ExtendedKey | VRFKey | KESKey
data DelegationCert
data StakePoolCert

newtype SecretKey = SecretKey { unSecret :: T.Text } deriving Show
newtype PublicKey = PublicKey { unPublic :: T.Text } deriving Show
newtype Address = Address { unAddress :: T.Text } deriving Show
newtype CertRegistration = CertRegistration { unCertReg :: T.Text } deriving Show
newtype SignedCert a = SignedCert { unSignedCert :: T.Text } deriving Show
newtype PoolId = PoolId { unPoolId :: T.Text } deriving Show
newtype Certificate a = Certificate { unCert :: T.Text} deriving Show

data StakePool = StakePool
  { leaderSecret :: SecretKey
  , leaderPublic :: PublicKey
  , leaderAddress :: Address
  , vrfSecret :: SecretKey
  , vrfPublic :: PublicKey
  , kesSecret :: SecretKey
  , kesPublic :: PublicKey
  , signedCertificate :: SignedCert StakePoolCert
  , signedDelegationCert :: SignedCert DelegationCert
  , stakePoolId :: PoolId
  } deriving Show

data StakePoolSecret = StakePoolSecret
  { nodeId :: PoolId
  , vrfKey :: SecretKey
  , sigKey :: SecretKey
  } deriving Generic

data InputConfig = InputConfig
  { stakePoolBalances :: [Integer]
  , stakePoolCount :: Int
  } deriving (Show, Generic)

instance FromJSON InputConfig where
  parseJSON = genericParseJSON defaultOptions

instance ToJSON StakePoolSecret where
  toJSON = genericToJSON (defaultOptions { fieldLabelModifier = camelTo2 '_' })

instance ToJSON SecretKey where
  toJSON (SecretKey key) = String key

instance ToJSON PoolId where
  toJSON (PoolId poolid) = String poolid

main :: IO ()
main = do
  args <- getArgs
  let
    go :: [Prelude.FilePath] -> IO ()
    go [path] = do
      ecfg <- eitherDecodeFileStrict path
      case ecfg of
        Left err -> do
          print err
          undefined
        Right cfg -> doEverything cfg
    doEverything :: InputConfig -> IO ()
    doEverything cfg = do
      stakePools <- generateStakePools (stakePoolCount cfg)
      let
        list2 = zip stakePools (stakePoolBalances cfg)
        certEntrie :: StakePool -> Value
        certEntrie StakePool{signedCertificate} = Object $ HM.fromList [("cert", String $ unSignedCert signedCertificate)]
        certDelegationEntry StakePool{signedDelegationCert} = Object $ HM.fromList [("cert", String $ unSignedCert signedDelegationCert)]
        certStakePoolEntries = map certEntrie stakePools
        certDelegationEntries = map certDelegationEntry stakePools
        generateFund (StakePool{leaderAddress}, balance) = Object $ HM.fromList [("address", String $ unAddress leaderAddress), ("value", Number $ fromInteger balance)]
        funds = map generateFund list2
        fund = Object $ HM.fromList [("fund", Array $ V.fromList funds)]
        initial = certStakePoolEntries <> certDelegationEntries <> [ fund ]
        writeSecrets :: (StakePool, Int) -> IO ()
        writeSecrets (StakePool{leaderPublic, leaderSecret, kesSecret, vrfSecret, stakePoolId, signedCertificate, signedDelegationCert}, index) = do
          let
            writeText :: Format Text (Int -> Text) -> Text -> IO ()
            writeText fmt content = writeFile (T.unpack $ format fmt index) (T.unpack content)
            secrets = StakePoolSecret stakePoolId vrfSecret kesSecret
          writeText ("leader_"%d%"_key.sk") (unSecret leaderSecret)
          writeText ("secret_pool_"%d%".yaml") (T.decodeUtf8 $ LBS.toStrict $ encode $ Object $ HM.fromList [("genesis", toJSON secrets)])
          writeText ("secret_pool_"%d%".signcert") (unSignedCert signedCertificate)
          writeText ("leader_"%d%"_delegation.signcert") (unSignedCert signedDelegationCert)
      encodeFile "genesis.initial.yaml" initial
      mapM_ writeSecrets (zip stakePools (range (1, stakePoolCount cfg)))
      pure ()
  go args

generateSecret :: Flag1 -> IO SecretKey
generateSecret keytype = do
  let
    typeTable NormalKey = "Ed25519"
    typeTable ExtendedKey = "Ed25519Extended"
    typeTable VRFKey = "Curve25519_2HashDH"
    typeTable KESKey = "SumEd25519_12"
    cmd = format ("jcli key generate --type="%s) (typeTable keytype)
  SecretKey . lineToText <$> single (inshell cmd empty)

generateFaucetData :: IO (SecretKey, PublicKey, Address)
generateFaucetData = do
  secret <- generateSecret NormalKey
  public <- secretToPublic secret
  address <- publicToAddress public
  pure (secret, public, address)

generateLeader :: IO (SecretKey, PublicKey)
generateLeader = do
  secret <- generateSecret NormalKey
  public <- secretToPublic secret
  pure (secret, public)

secretToPublic :: SecretKey -> IO PublicKey
secretToPublic (SecretKey sec) = do
  let secStream = toLines $ select [ sec ]
  PublicKey . lineToText <$> single (inshell "jcli key to-public" secStream)

publicToAddress :: PublicKey -> IO Address
publicToAddress (PublicKey pub) = do
  let cmd = format ("jcli address account "%s) pub
  Address . lineToText <$> single (inshell cmd empty)

generateStakePool :: IO StakePool
generateStakePool = do
  (leaderSecret, leaderPublic) <- generateLeader
  vrfSecret <- generateSecret VRFKey
  vrfPublic <- secretToPublic vrfSecret
  kesSecret <- generateSecret KESKey
  kesPublic <- secretToPublic kesSecret
  leaderAddress <- publicToAddress leaderPublic
  let
    cmd = format ("jcli certificate new stake-pool-registration --kes-key "%s%" --vrf-key "%s%" --owner "%s%" --serial 1010101010 --management-threshold 1 --start-validity 0") (unPublic kesPublic) (unPublic vrfPublic) (unPublic leaderPublic)
  certRegistration <- Certificate . lineToText <$> single (inshell cmd empty)
  signedCertificate <- signCertificate certRegistration leaderSecret
  stakePoolId <- getPoolId signedCertificate
  let
    cmd2 = format ("jcli certificate new stake-delegation "%s%" "%s) (unPoolId stakePoolId) (unPublic leaderPublic)
  delegationCert <- Certificate . lineToText <$> single (inshell cmd2 empty)
  signedDelegationCert <- signCertificate delegationCert leaderSecret
  pure $ StakePool{leaderSecret, leaderPublic, leaderAddress, vrfSecret, vrfPublic, kesSecret, kesPublic, signedCertificate, signedDelegationCert, stakePoolId}

generateStakePools :: Int -> IO [StakePool]
generateStakePools count = mapM (\_ -> generateStakePool) (range (1,count))

signCertificate :: Certificate a -> SecretKey -> IO (SignedCert a)
signCertificate certreg (SecretKey secret) = do
  let
    go :: Managed (SignedCert a)
    go = do
      leaderSecretPath <- mktempfile "/tmp/" "secret.???"
      liftIO $ writeFile (encodeString leaderSecretPath) (T.unpack secret)
      let
        cmd = format ("jcli certificate sign "%fp) leaderSecretPath
      SignedCert . lineToText <$> single (inshell cmd (toLines $ select [ unCert certreg ]))
  with go (\result -> pure result)

getPoolId :: SignedCert StakePoolCert -> IO PoolId
getPoolId (SignedCert signedCert) = do
  PoolId . lineToText <$> single (inshell "jcli certificate get-stake-pool-id" (toLines $ select [ signedCert ]))
