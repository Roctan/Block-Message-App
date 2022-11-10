// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract database {
    struct user {
        string name;
        friend[] friendList;
    }
    struct friend {
        address pubKey;
        string name;
    }
    struct message {
        address sender;
        uint256 timestamp;
        string mesg;
    }
    mapping(address => user) userList;
    mapping(bytes32 => message[]) allMessages;

    function checkUser(address pubKey) public view returns (bool) {
        return bytes(userList[pubKey].name).length > 0;
    }

    function createAccount(string calldata name) external {
        require(checkUser(msg.sender) == false, "User Already exists!");
        require(bytes(name).length > 0, "Username cannot be empty!");
        userList[msg.sender].name = name;
    }

    function getUsername(address pubKey) external view returns (string memory) {
        require(checkUser(pubKey), "User is not registered!");
        return userList[pubKey].name;
    }

    function checkAlreadyFriends(address pubKey1, address pubKey2)
        internal
        view
        returns (bool)
    {
        if (
            userList[pubKey1].friendList.length >
            userList[pubKey2].friendList.length
        ) {
            address tmp = pubKey1;
            pubKey1 = pubKey2;
            pubKey2 = tmp;
        }
        for (uint i = 0; i < userList[pubKey1].friendList.length; i++) {
            if (userList[pubKey1].friendList[i].pubKey == pubKey2) return true;
        }
        return false;
    }

    function addfriend(address friend_key, string calldata name) external {
        require(
            checkUser(msg.sender),
            "user not registered! Create an account."
        );
        require(checkUser(friend_key), "User is not registered!");
        require(msg.sender != friend_key, "Both keys are same!");
        require(
            checkAlreadyFriends(msg.sender, friend_key) == false,
            "Already friends!"
        );

        _addFriend(msg.sender, friend_key, name);
        _addFriend(friend_key, msg.sender, userList[msg.sender].name);
    }

    function _addFriend(
        address me,
        address friend_key,
        string memory name
    ) internal {
        friend memory newfriend = friend(friend_key, name);
        userList[me].friendList.push(newfriend);
    }

    //returns list of friends of sender
    function getMyFriendList() external view returns (friend[] memory) {
        return userList[msg.sender].friendList;
    }

    function _getChatCode(address pubKey1, address pubKey2)
        internal
        pure
        returns (bytes32)
    {
        if (pubKey1 < pubKey2)
            return keccak256(abi.encodePacked(pubKey1, pubKey2));
        else return keccak256(abi.encodePacked(pubKey2, pubKey1));
    }

    function sendMessage(address friend_key, string calldata _msg) external {
        require(checkUser(msg.sender), "Create an Account!");
        require(checkUser(friend_key), "User not registered!");
        require(
            checkAlreadyFriends(msg.sender, friend_key),
            "You both are not friends"
        );

        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        message memory newMsg = message(msg.sender, block.timestamp, _msg);
        allMessages[chatCode].push(newMsg);
    }

    function readMessage(address friend_key)
        external
        view
        returns (message[] memory)
    {
        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        return allMessages[chatCode];
    }
}
