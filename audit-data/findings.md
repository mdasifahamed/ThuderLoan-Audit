### [H-] LiquidityProvider Token Can Be Locked For Misuse `AssetToken::updateExcahngeRate()` At `ThunderLoan::deposit()`. LiquidityProvider will be unable to withdraw his token.

**Description:** At `ThunderLoan::deposit()` it updates `AssetToken::s_exchangeRate` based on the amount a lp is going to deposit. and `AssetToken::s_exchangeRate` again updated at `ThunderLoan::flashLoan()` which breaks the fee in `ThunderLoan::redeem()` thus lp fund is locked locked in the protocol.

Vulnerable code

```javascript
    function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {

        AssetToken assetToken = s_tokenToAssetToken[token]; // it fetches asset Token based on allowed asset/uderlying token pair
        uint256 exchangeRate = assetToken.getExchangeRate(); /// comes from asset Contract

        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        // @ audit It breaks the protocol 
        // user deposited amount is locked for updating exchanging rate here
 @>      uint256 calculatedFee = getCalculatedFee(token, amount);
 @>      assetToken.updateExchangeRate(calculatedFee); // but why updating excahnge with falshloan fee

        token.safeTransferFrom(msg.sender, address(assetToken), amount);// asset token has right to use underlying token now.
    }

```
**Impact:** LiquidityProvider Fund Are Locked.


**Proof of Concept:**

1. LiquidityProvider Deposits Fund
2. A User Takes FlashLoan
3. LiquidityProvider trie to Redeem  It Fails


Add the Following scritp to `./test/unit/ThunderLoanTest.t.sol` And Run `forge test --match-test testCantReddem -vvvvv`

```javascript
    function testCantReddem() public setAllowedToken hasDeposits(){
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, DEPOSIT_AMOUNT);

    } 
```

**Recommended Mitigation:** Remove The Following Line Of The Code From The `ThunderLoan::deposit()`

```diff
-    uint256 calculatedFee = getCalculatedFee(token, amount);
-    assetToken.updateExchangeRate(calculatedFee);
```