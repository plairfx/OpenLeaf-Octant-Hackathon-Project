## OpenLeaf

OpenLeaf is a public good/project that is meant to support:
- Transparency from protocols
- User Engagement/Community
- Earning Yield from unused funds

OpenLeaf does that by allowing protocols to add their project, they can create tasks, earn yield and show transparency by submitting information about their activity.

**Protocols**
- Create Tasks where users can participate and earn money from
- Earn yield through OpenLeaf's Strategies and use the yield for funding tasks

**Users**
- Create Submissions and Earn money!
- Research the protocol they are invested in through Openleaf which allows to track transaction/direction a protocol makes.



## How does it work?




### Future goals
- Enable Contract monitoring
- Enable Submitting TX info for transactions from protocol owners.
- Let users submit info/tx's they are concerned about to Openleaf





### Setup
```shell
$ forge install
```

```shell
$ forge build
```

## Testing 

```shell
$ forge test
```

### Local Deployment

Deploy a mainnet fork using a Ethereum RPC. (SEE env.local for required variables)
```shell
anvil --chain-id 31337 --fork-url $MAINNET_RPC_URL
```

Deploy the script.

```shell
forge script script/DeployOpenLeaf.sol --fork-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Deployment Steps

Impersonate a whale and get yourself some USDC. (USE ANVIL's first account) as private key.

```shell
cast rpc anvil_impersonateAccount 0x46340b20830761efd32832A74d7169B29FEB9758 --rpc-url http://localhost:8545
```

Send yourself some mainnet USDC! (This sends USDC to anvil 1st address)

```shell
cast send 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 \
  "transfer(address,uint256)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  100000000 \
  --from 0x46340b20830761efd32832A74d7169B29FEB9758 \
  --rpc-url http://localhost:8545
```
