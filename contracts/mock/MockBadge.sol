// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockBadge is ERC1155 {
    constructor() ERC1155("") {}

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _mint(account, id, amount, "");
    }
}
