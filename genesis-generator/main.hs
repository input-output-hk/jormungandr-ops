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
import Data.List.Split

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

data Genesis = Genesis
  { blockchainConfiguration :: BlockchainConfig
  , initial :: [Value]
  } deriving Generic

data BlockchainConfig = BlockchainConfig
  { bftSlotsRatio :: Int
  , block0Consensus :: T.Text --  = "genesis_praos";
  , block0Date :: Int
  , consensusGenesisPraosActiveSlotCoeff :: Float
  , consensusLeaderIds :: [PublicKey]
  , discrimination :: T.Text -- "test";
  , epoch_stability_depth :: Int
  , kesUpdateSpeed :: Int
  , linearFees :: LinearFees
  , maxNumberOfTransactionsPerBlock :: Int
  , slotDuration :: Int
  , slotsPerEpoch :: Int
  } deriving (Show, Generic)

instance FromJSON BlockchainConfig where
  parseJSON = genericParseJSON customOptions

instance ToJSON BlockchainConfig where
  toJSON = genericToJSON customOptions

data LinearFees = LinearFees
  { certificate :: Int
  , coefficient :: Int
  , constant :: Int
  } deriving (Show, Generic)

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
  , inputBlockchainConfig :: BlockchainConfig
  , extraLegacyFunds :: [Value]
  , extraFunds :: [Value]
  , extraDelegationCerts :: [ SignedCert DelegationCert ]
  , extraStakePools :: [ SignedCert StakePoolCert ]
  } deriving (Show, Generic)

customOptions = defaultOptions { fieldLabelModifier = camelTo2 '_' }
instance FromJSON InputConfig where
  parseJSON = withObject "InputConfig" $ \o -> InputConfig
    <$> o .: "stakePoolBalances"
    <*> o .: "stakePoolCount"
    <*> o .: "inputBlockchainConfig"
    <*> o .: "extraLegacyFunds"
    <*> o .: "extraFunds"
    <*> ((map SignedCert) <$> o .: "extraDelegationCerts")
    <*> ((map SignedCert) <$> o .: "extraStakePools")

instance ToJSON StakePoolSecret where
  toJSON = genericToJSON customOptions

instance ToJSON SecretKey where
  toJSON (SecretKey key) = String key

instance FromJSON PublicKey where
  parseJSON (String str) = pure $ PublicKey str

instance ToJSON PublicKey where
  toJSON (PublicKey pk) = String pk

instance ToJSON PoolId where
  toJSON (PoolId poolid) = String poolid

instance ToJSON Genesis where
  toJSON = genericToJSON customOptions

instance ToJSON LinearFees where
  toJSON = genericToJSON customOptions

instance FromJSON LinearFees where
  parseJSON = genericParseJSON customOptions

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
      voter1 <- generateSecret NormalKey
      voter2 <- generateSecret NormalKey
      voter1pub <- secretToPublic voter1
      voter2pub <- secretToPublic voter2
      let
        list2 = zip stakePools (stakePoolBalances cfg)
        certEntry :: StakePool -> Value
        certEntry StakePool{signedCertificate} = Object $ HM.fromList [("cert", String $ unSignedCert signedCertificate)]
        certDelegationEntry :: StakePool -> Value
        certDelegationEntry StakePool{signedDelegationCert} = Object $ HM.fromList [("cert", String $ unSignedCert signedDelegationCert)]
        wrapExtraCert :: SignedCert a -> Value
        wrapExtraCert SignedCert{unSignedCert} = Object $ HM.fromList [("cert", String $ unSignedCert )]
        certStakePoolEntries :: [Value]
        certStakePoolEntries = map certEntry stakePools
        -- returns a list of [{"cert":"..."}]
        certDelegationEntries = map certDelegationEntry (take (length $ stakePoolBalances cfg) stakePools)
        extraStakePoolCerts = map wrapExtraCert (extraStakePools cfg)
        -- also returns a list of [{"cert":"..."}] for the extra delegations
        extraDelegationEntries = map wrapExtraCert (extraDelegationCerts cfg)
        generateFund :: (StakePool, Integer) -> Value
        generateFund (StakePool{leaderAddress}, balance) = Object $ HM.fromList [("address", String $ unAddress leaderAddress), ("value", Number $ fromInteger balance)]
        allFunds :: [Value]
        allFunds = map generateFund list2
        chunkedFunds = chunksOf 255 (allFunds <> extraFunds cfg)
        legacyChunks = chunksOf 254 (extraLegacyFunds cfg)
        mkLegacyFund chunk = Object $ HM.fromList [("legacy_fund", Array $ V.fromList chunk)]
        mkFund chunk = Object $ HM.fromList [("fund", Array $ V.fromList chunk)]
        fund = map mkFund chunkedFunds
        legacy_fund = map mkLegacyFund legacyChunks
        initial = fund <> legacy_fund <> certStakePoolEntries <> extraStakePoolCerts <> certDelegationEntries <> extraDelegationEntries
        modifiedblockconfig = (inputBlockchainConfig cfg) {
          consensusLeaderIds = [ voter1pub, voter2pub ]
        }
        genesisYaml = Genesis modifiedblockconfig initial
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
      encodeFile "genesis.yaml" genesisYaml
      writeFile "voter1.sk" (T.unpack $ unSecret voter1)
      writeFile "voter2.sk" (T.unpack $ unSecret voter2)
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
  let cmd = format ("jcli address account --testing "%s) pub
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
        cmd = format ("jcli certificate sign -k "%fp) leaderSecretPath
      SignedCert . lineToText <$> single (inshell cmd (toLines $ select [ unCert certreg ]))
  with go (\result -> pure result)

getPoolId :: SignedCert StakePoolCert -> IO PoolId
getPoolId (SignedCert signedCert) = do
  PoolId . lineToText <$> single (inshell "jcli certificate get-stake-pool-id" (toLines $ select [ signedCert ]))
