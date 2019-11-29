# example usage: nix-build generate-nightly.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 7;
  stakePoolBalances = __genList (_: ada 10000000) stakePoolCount;

  extraBlockchainConfig = {
    linear_fees = {
      constant = 2;
      coefficient = 1;
      certificate = 4;
    };

    treasury = 0;

    treasury_parameters = {
      fixed = 1000;
      ratio = "1/10";
    };

    total_reward_supply = ada 10000000;

    reward_parameters = {
      halving = {
        constant = 100;
        ratio = "13/19";
        epoch_start = 1;
        epoch_rate = 3;
      };
    };
  };

  inputParams = {
    extraLegacyFunds = [
      { "address" = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 100000; }
      { "address" = "DdzFFzCqrht1zDLWxw9hLEgzKogvkGH3KNNTCjADNreP8FTczsxMd7VG1k4qRHezZNQhgx6fHUa1NA54acajnENFymHxcEZrvgjG1p23"; value = ada 100000; }
    ];
    extraFunds = [
      { address = "ca1s5j5kpfd6kwehx6r4ttq3mgdddd9ald97e3pcg0zn9m9493hq9axctwxjl4"; value = ada 10000000; }
      { address = "ca1shmg2lghpxvsmgjz4duewzka5xn7z5rsk6aljtdsjzfpx8hcgjlyq2ks36q"; value = ada 1000000; }
      { address = "ca1s5an22g0k9xq4jww0n0yqgzfymsnk8p8587nw4kxnqgcxf9lq52dwqgusv0"; value = ada 1000000; }
      { address = "ca1sk5nh8kkcsw4gcda7fyszfaxwrmyndh9r447yrjx4kzwpgnmlpmdqkr5lm4"; value = ada 1000000; }
    ];
    extraDelegationCerts = [
      "signedcert1qyj5kpfd6kwehx6r4ttq3mgdddd9ald97e3pcg0zn9m9493hq9axcqfs2svfmf83hxz5d3669rslta9h70vk54jkeugf96m0gxlaq8gsjuqm5ms4pp338zzxymvzxhn4vc0a373zntnhe2jpgeyxje900kf923u5r632y6v4h4yd6xmqpfhgp5un8qq9j5t845vgwd9smspn4qh4pcvp82n8"
      "signedcert1q8mg2lghpxvsmgjz4duewzka5xn7z5rsk6aljtdsjzfpx8hcgjlyqq26p00pgxmkzstlsh9z04lyhw32khd7rk5pk0pw3t0lu0076jgpnuq6tmymlrhpy30e486jgpahzd20hkwhecjxtdjd86tvazs8m2ktsz3c803m4f5kqs800xu9l0mu86c5hvds5m3qj4g0cgtznwvq05h4pyruyad9"

    ];
    extraStakePools = [
      "signedcert1qvqqqqqqqqqqqqqqqqqqq0p5avfqqqqqqqqqqqqqqqqqqqqqqqqqru5txnye6jjkqwv5cf0lwm7pakzk6e6c5dqzyyx3cve8wtggsn24ykpl2usa6rxjymgk598qhpaxdsculpfp5c04veq77lvr4y3nea3qzf2tq5kat8vmndp644sga5xkkkj7lkjlvcsuy83fjaj6jcmsz7nvqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqqqqqqqqqqqqqqpqqya4e9f8lk2yg7dxpkt6c558fly63nun0zszapddrxj3vml95evlmj9xe7c9q99s52e28z5l0kecncc0c6jse0ym9m34gqrfrrfats2vldfen"
     "signedcert1qvqqqqqqqqqqqqqqqqqqq0p5avfqqqqqqqqqqqqqqqqqqqqqqqqqrkks683u4c7n2dac643xjr3tyjwwcmv2c80k4rzyfj3c0nhhw2zyp6mpka2d2puq4cr9t0twuyqaf3xtujpmz2w7maua8dahjzwwjvzqra5905tsnxgd5fp2k7vhptw6rflp2pctdwle9kcfpysnrmuyf0jqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqqqqqqqqqqqqqqpqpvves4ds857muzcvw59xhrg567duc5j9pgqjmq9vl9xcfuwdqqsf2ze3d3e3rq54rnufwnm40n4smta7aamfk7nms4s7ljgr2szexqdf5aups"
    ];
  };
in import ./. { inherit inputParams stakePoolCount stakePoolBalances extraBlockchainConfig; }
