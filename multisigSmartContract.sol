pragma solidity 0.8.17;
pragma abicoder v2;

/*
This is a practice project to build a multisig wallet
This wallet holds multiple address as owners,
anyone can deposit into it, but in order to withdraw it needs at least
2/3 of the owners approval in order to do so. 
*/

contract Wallet {
    address[] public owners; //array that store the address of owners
    uint limit; //number of signatures required to approve transfer transaction
    
    struct Transfer{
        uint amount;
        address payable receiver;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }
    
    //events that triggers various functions
    event TransferRequestCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);

    Transfer[] transferRequests;
    
    mapping(address => mapping(uint => bool)) approvals;
    
    //Should only allow people in the owners list to continue the execution.
    modifier onlyOwners(){
        bool owner = false;
        //loop through the entire list of owners and only change owner to true if 
        //the msg.sender address matches ones that is listed in the array, signifying its an owner
        for(uint i=0; i<owners.length;i++){
            if(owners[i] == msg.sender){
                owner = true;
            }
        }
        require(owner == true); //check if owner is true, then continue, else throws error
        _; //run the function/ modifier
    }
    //Constructors are used initialize the owners list and the limit 
    constructor(address[] memory _owners, uint _limit) {
        owners = _owners;
        limit = _limit;
    }
    
    //Empty function, this function is use for depositing into
    //and doesn't require any computation to process deposit, thus can be empty
    function deposit() public payable {}
    
    //Create an instance of the Transfer struct and add it to the transferRequests array
    //only onlyOwners can call this function and create transfer
    function createTransfer(uint _amount, address payable _receiver) public onlyOwners {
        //emitting an event
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        //.push, push it into the transferRequests array
        transferRequests.push(
            //Transfer is define in the struct and has the ordered parameter
            //_amount = amount to transfer, _reciever = reciever address,
            //0 = no owners have approved the transfer yet,
            //false = have not been send yet
            //transferRequests.length = the ID of each transfer requests, start from 0
            Transfer(_amount, _receiver, 0, false, transferRequests.length)
        );
        
    }
    
    //Set your approval for one of the transfer requests.
    //Need to update the Transfer object.
    //Need to update the mapping to record the approval for the msg.sender.
    //When the amount of approvals for a transfer has reached the limit, this function should send the transfer to the recipient.
    //An owner should not be able to vote twice.
    //An owner should not be able to vote on a tranfer request that has already been sent.
    function approve(uint _id) public onlyOwners {
        require(approvals[msg.sender][_id] == false); //owners shouldn't be able to vote twice
        require(transferRequests[_id].hasBeenSent == false); //owners shouldn't be able to vote on a transfer request already been sent
        
        approvals[msg.sender][_id] = true; 
        transferRequests[_id].approvals++;
        
        emit ApprovalReceived(_id, transferRequests[_id].approvals, msg.sender);
        //check if amount of approvals, set by limit, have been reach
        if(transferRequests[_id].approvals >= limit){
            //set the hasBeenSent to true
            transferRequests[_id].hasBeenSent = true;
            transferRequests[_id].receiver.transfer(transferRequests[_id].amount); //actualy transfering the fund
            emit TransferApproved(_id);
        }
    }
    
    //Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory){
        return transferRequests;
    }
    
    
}
