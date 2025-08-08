// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Common.sol";

contract StandardNFTTest is Common {

    function test_factoryDeployment() public view {
        assertEq(address(factory.nftImplementation()), address(nft));
        assertEq(factory.treasury(), beneficiary);
        assertEq(factory.owner(), owner);
        assertEq(factory.creationFee(), 1 ether);
        assertEq(factory.getTotalNFT(), 0);
        assertTrue(factory.paused() == false);
    }

    function test_createNFT() public returns (StandardNFT newNft) {
        string memory name = "Test StandardNFT";
        string memory symbol = "TEST";
        string memory baseURI = "https://example.com/metadata.json/";

        vm.startPrank(user);
        newNft = StandardNFT(factory.createNFT{value: factory.creationFee()}(
            name, 
            symbol, 
            baseURI
        ));

        newNft.safeMint(user); // Mint StandardNFT token ID 0 to user
        vm.stopPrank();

        assertEq(newNft.name(), name);
        assertEq(newNft.symbol(), symbol);
        assertEq(newNft.ownerOf(0), user);
        assertEq(newNft.totalSupply(), 1);
        assertFalse(newNft.isMetadataLocked());
        assertEq(newNft.tokenURI(0), string(abi.encodePacked(baseURI, "0")));
        assertEq(beneficiary.balance, factory.creationFee());
    }
    

    function test_setBaseURI() public {
        string memory newURI = "https://example.com/new_metadata.json/";

        StandardNFT newNft = test_createNFT();

        vm.prank(user);
        newNft.setBaseURI(newURI);

        assertEq(newNft.tokenURI(0), string(abi.encodePacked(newURI, "0")));
    }

    function test_lockMetadata() public {
        StandardNFT newNft = test_createNFT();

        vm.prank(user);
        newNft.lockMetadata();

        assertTrue(newNft.isMetadataLocked());

        vm.expectRevert();
        
        vm.prank(user);
        newNft.setBaseURI("https://example.com/locked_metadata.json/");
    }

    function test_totalSupply() public {
        StandardNFT newNft = test_createNFT();

        assertEq(newNft.totalSupply(), 1);

        vm.prank(user);
        newNft.safeMint(user); // Mint another StandardNFT token ID 1 to user

        assertEq(newNft.totalSupply(), 2);
    }

    function test_isMetadataLocked() public {
        StandardNFT newNft = test_createNFT();

        assertFalse(newNft.isMetadataLocked());

        vm.prank(user);
        newNft.lockMetadata();

        assertTrue(newNft.isMetadataLocked());
    }

    function test_balanceOf() public {
        StandardNFT newNft = test_createNFT();

        assertEq(newNft.balanceOf(user), 1);

        vm.prank(user);
        newNft.safeMint(user); // Mint another StandardNFT token ID 1 to user

        assertEq(newNft.balanceOf(user), 2);
    }

    function test_ownerOf() public {
        StandardNFT newNft = test_createNFT();

        assertEq(newNft.ownerOf(0), user);

        vm.prank(user);
        newNft.safeMint(user); // Mint another StandardNFT token ID 1 to user

        assertEq(newNft.ownerOf(1), user);
    }

    function test_transferFrom() public {
        StandardNFT newNft = test_createNFT();

        vm.prank(user);
        newNft.transferFrom(user, address(this), 0);

        assertEq(newNft.ownerOf(0), address(this));
        assertEq(newNft.balanceOf(user), 0);
        assertEq(newNft.balanceOf(address(this)), 1);
    }

    function test_safeTransferFrom() public {
        StandardNFT newNft = test_createNFT();

        vm.prank(user);
        newNft.safeTransferFrom(user, user2, 0);

        assertEq(newNft.ownerOf(0), user2);
        assertEq(newNft.balanceOf(user), 0);
        assertEq(newNft.balanceOf(user2), 1);
    }
}