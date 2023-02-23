// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

/// @dev Factory dependencies.
import {IOU} from "./IOU.sol";

/// @dev Core dependencies.
import {IIOUFactory} from "./interfaces/IIOUFactory.sol";
import {IIOU} from "./interfaces/IIOU.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Helper dependencies.
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Libraries.
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @dev Factory contract that deploys IOUs for assets held on another chain
 *      on top of a trusted party distribution mechanism.
 */
contract IOUFactory is IIOUFactory, Ownable {
    using Clones for address;

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The address of the IOU implementation.
    address public immutable implementation;

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

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor(
        address _implementation,
        address _signer,
        address _vault,
        Badge memory _badge
    ) {
        /// @dev Set the implementation.
        implementation = _implementation;

        /// @dev Set the signer.
        _setSigner(_signer);

        /// @dev Set the vault.
        _setVault(_vault);

        /// @dev Set the Badge.
        _setBadge(_badge);
    }

    ////////////////////////////////////////////////////////
    ///                     MODIFIERS                     ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Modifier to confirm the user has the badge.
     */
    modifier onlyBadgeHolder() {
        /// @dev Confirm the user has the badge.
        require(
            badge.token.balanceOf(msg.sender, badge.id) >= badge.amount,
            "IOU: Missing Badge that grants access to mint."
        );

        _;
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the signer address.
     * @param _signer The address of the signer.
     */
    function setSigner(address _signer) external onlyOwner {
        /// @dev Set the signer.
        _setSigner(_signer);
    }

    /**
     * @dev Set the vault address.
     * @param _vault The address of the vault.
     */
    function setVault(address _vault) external onlyOwner {
        /// @dev Set the vault.
        _setVault(_vault);
    }

    /**
     * @dev Set the Badge.
     * @param _badge The address of the Badge.
     */
    function setBadge(Badge memory _badge) external onlyOwner {
        /// @dev Set the Badge.
        _setBadge(_badge);
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
        onlyBadgeHolder
        returns (IOU iou, uint256 iouId)
    {
        /// @dev Increment the id.
        unchecked {
            iouId = ious++;
        }

        /// @dev CLone the contract using the iouID as salt.
        address iouAddress = implementation.cloneDeterministic(
            keccak256(abi.encodePacked(iouId))
        );

        /// @dev Interface with the new contract.
        iou = IOU(iouAddress);

        /// @dev Initialize the IOU.
        iou.initialize(_receipt);

        /// @dev Emit an event to signal the creation of the IOU.
        emit IOUCreated(iou, msg.sender, iouId);
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

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

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    function _setSigner(address _signer) internal {
        signer = _signer;

        /// @dev Emit an event to signal the change of the signer.
        emit SignerUpdated(_signer);
    }

    function _setVault(address _vault) internal {
        vault = _vault;

        /// @dev Emit an event to signal the change of the vault.
        emit VaultUpdated(_vault);
    }

    function _setBadge(Badge memory _badge) internal {
        require(
            IERC165(_badge.token).supportsInterface(type(IERC1155).interfaceId),
            "IOU: Badge token does not support IERC1155."
        );

        /// @dev Set the Badge.
        badge = _badge;

        /// @dev Emit an event to signal the change of the Badge.
        emit BadgeUpdated(_badge);
    }

    /**
     * @dev Get the address of an IOU.
     * @param _iouId The id of the IOU.
     */
    function getIOU(uint256 _iouId) external view returns (IOU) {
        /// @dev Get the address of the IOU if it exists.
        return
            IOU(
                implementation.predictDeterministicAddress(
                    keccak256(abi.encodePacked(_iouId)),
                    address(this)
                )
            );
    }
}
