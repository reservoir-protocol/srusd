import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface ISavingcoin is IERC20Metadata, IERC4626 {
    function cap() external view returns(uint256);
    function apy() external view returns(uint256);
    function currentRate() external view returns(uint256);
}
