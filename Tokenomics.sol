/**
 * author: 0f0crypto <00ff00crypto@gmail.com>
 * discord: https://discord.gg/zn86MDCQcM
 *
 * Safetoken v1.0beta
 *
 * This is a rewrite of Safemoon in the hope to:
 *
 * - make it easier to change the tokenomics
 * - make it easier to maintain the code and develop it further
 * - remove redundant code
 * - fix some of the issues reported in the Safemoon audit (e.g. SSL-03)
 *      https://www.certik.org/projects/safemoon
 *
 *
 * ░██████╗░█████╗░███████╗███████╗████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
 * ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
 * ╚█████╗░███████║█████╗░░█████╗░░░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
 * ░╚═══██╗██╔══██║██╔══╝░░██╔══╝░░░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
 * ██████╔╝██║░░██║██║░░░░░███████╗░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
 * ╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚══════╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.4;

/**
 * Tokenomics: (4% of each transaction)
 *
 * Redistribution   0.8%
 * Burn             0.08%
 * Advisors         3.12%
 */

/**
 *
 * You can add (in theory) as many custom taxes/fees with dedicated wallet addresses if you want.
 * Nevertheless, I do not recommend using more than a few as the contract has not been tested
 * for more than the original number of taxes/fees, which is 6 (liquidity, redistribution, burn,
 * marketing, charity & tip to the dev). Furthermore, exchanges may impose a limit on the total
 * transaction fee (so that, for example, you cannot claim 100%). Usually this is done by limiting the
 * max value of slippage, for example, PancakeSwap max slippage is 49.9% and the fees total of more than
 * 35% will most likely fail there.
 *
 * NOTE: You shouldn't really remove the Rfi fee. If you do not wish to use RFI for your token,
 * you shouldn't be using this contract at all (you're just wasting gas if you do).
 *
 * NOTE: ignore the note below (anti-whale mech is not implemented yet)
 * If you wish to modify the anti-whale mech (progressive taxation) it will require a bit of coding.
 * I tried to make the integration as simple as possible via the `Antiwhale` contract, so the devs
 * know exactly where to look and what/how to make the necessary changes. There are many possibilites,
 * such as modifying the fees based on the tx amount (as % of TOTAL_SUPPLY), or sender's wallet balance
 * (as % of TOTAL_SUPPLY), including (but not limited to):
 * - progressive taxation by tax brackets (e.g <1%, 1-2%, 2-5%, 5-10%)
 * - progressive taxation by the % over a threshold (e.g. 1%)
 * - extra fee (e.g. double) over a threshold
 */
contract Tokenomics {
    mapping(address => uint256) internal _reflectedBalances;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;
    mapping(address => bool) internal _isExcludedFromRewards;
    // --------------------- Token Settings ------------------- //

    address internal dailyOperationsAddress;

    // --------------------- Fees Settings ------------------- //

    /**
     * @dev To add/edit/remove fees scroll down to the `addFees` function below
     */

    address internal advisorsAddress;
	address internal teamAddress;
    address internal burnAddress;

    enum FeeType {
        Burn,
        Rfi,
        External
    }
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    function _addFee(
        FeeType name,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() internal {
        /**
         * The RFI recipient is ignored but we need to give a valid address value
         *
         * CAUTION: If you don't want to use RFI this implementation isn't really for you!
         *      There are much more efficient and cleaner token contracts without RFI
         *      so you should use one of those
         *
         * The value of fees is given in part per 1000 (based on the value of FEES_DIVISOR),
         * e.g. for 5% use 500, for 3.5% use 350, etc.
         */
        //4%
        _addFee(FeeType.Rfi, 80, address(this)); //Redistribution 0.8%

        _addFee(FeeType.Burn, 8, burnAddress); //Burn 0.08%
        _addFee(FeeType.External, 312, advisorsAddress); //company 3.12%
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function _getFee(uint256 index)
        internal
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total + amount;
    }

    // function getCollectedFeeTotal(uint256 index) external view returns (uint256){
    function getCollectedFeeTotal(uint256 index)
        internal
        view
        returns (uint256)
    {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}
