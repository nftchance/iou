// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

/// @dev Factory dependencies.
import {IOU} from "./IOU.sol";

/// @dev Core dependencies.
import {IIOUFactory} from "./interfaces/IIOUFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Helper dependencies.
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Libraries.
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

/**
 * @dev Factory contract that deploys IOUs for assets held on another chain
 *      on top of a trusted party distribution mechanism.
 */
contract IOUFactory is IIOUFactory, Ownable {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev Keeping track of the signer providing the valid signature
    ///      that confirms the IOU is valid.
    address public signer;

    /// @dev The address to send IOUs to when they are redeemed.
    address public vault;

    /// @dev The Badge that grants access to users.
    Badge public badge;

    /// @dev Keeping track of how many IOUs have been created.
    uint256 public ious;

    /// @dev Hotslot for the receipt last deployed.
    Receipt public receipt;

    /// @dev Hotslot for the last address that deployed an IOU.
    address public lastDeployer;

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the signer address.
     * @param _signer The address of the signer.
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;

        /// @dev Emit an event to signal the change of the signer.
        emit SignerUpdated(_signer);
    }

    /**
     * @dev Set the vault address.
     * @param _vault The address of the vault.
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;

        /// @dev Emit an event to signal the change of the vault.
        emit VaultUpdated(_vault);
    }

    /**
     * @dev Set the Badge.
     * @param _badge The address of the Badge.
     */
    function setBadge(Badge calldata _badge) external onlyOwner {
        /// @dev Set the Badge.
        badge = _badge;

        /// @dev Emit an event to signal the change of the Badge.
        emit BadgeUpdated(_badge);
    }

    /**
     * @dev Create a new IOU.
     * @param _receipt The receipt containing the data needed to create the IOU.
     * @return iou The address of the newly created IOU.
     * @return iouId The id of the newly created IOU.
     */
    function createIOU(Receipt calldata _receipt)
        public
        virtual
        returns (IOU iou, uint256 iouId)
    {
        /// @dev Increment the id.
        unchecked {
            iouId = ious++;
        }

        /// @dev Save the IOU into the hotslot.
        receipt = _receipt;

        /// @dev Save the deployer into the hotslot.
        lastDeployer = msg.sender;

        /// @dev Deploy the new IOU contract.
        iou = new IOU{salt: bytes32(iouId)}();

        /// @dev Emit an event to signal the creation of the IOU.
        emit IOUCreated(iou, msg.sender, iouId);
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Get the IOU address given a specific id.
     * @param _iouId The id of the IOU.
     * @return iou The address of the IOU.
     */
    function getIOU(uint256 _iouId) external view returns (IOU iou) {
        return
            IOU(
                payable(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(_iouId),
                            keccak256(abi.encodePacked(type(IOU).creationCode))
                        )
                    ).fromLast20Bytes()
                )
            );
    }

    /**
     * @dev Get the value of name set in the hotslot.
     */
    function name() external view returns (string memory) {
        return receipt.name;
    }

    /**
     * @dev Get the value of symbol set in the hotslot.
     */
    function symbol() external view returns (string memory) {
        return receipt.symbol;
    }
}
