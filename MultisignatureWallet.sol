pragma solidity 0.7.4;

//
// Requirements:
// 1.)  Anybody can deposit
// 2.)  The contract creator should be able to input 
//      (1): The addresses of the owners
//      (2): The numbers of approvals required for a transfer, in the constructor. 
//      For example, input 3 addresses and set the approval limit to 2
// 3.)  Anyone of the owners should be able to create a transfer request. 
//      The creator of the transfer request will specify the amount and target addresses
// 4.)  Owners should be able to approve transfer requests
// 5.)  When a transfer request has the required approvals, the transfer should be sent.
//

import "./_Interfaces/IPayable.sol";
import "./_Interfaces/IOwnable.sol";

// Requirement 1:   IPayable
// Requirement 2.1: IOwnable
contract MultisignatureWallet is 
    IOwnable, 
    IPayable
{
    // Transfer Request Structure
    struct TransferRequest
    {
        uint            uiId;
        uint            uiAmountInWei;
        uint            uiApprovals;
        address payable aRecipient;
    }
    
    modifier __Mod_AdminOnly
    {
        require(m_mapAdministrators[msg.sender] == true, "Sender is not an administrator");
        _;
    }
    
    modifier __Mod_Affordable(uint _uiAmountInWei)
    {
        require(address(this).balance >= _uiAmountInWei, "Wallet does not have enough funds to process transaction");
        _;
    }
    
    event LogAdministratorRegister(address _uiAdministrator);
    event LogTransferRequested(uint _uiId, uint _uiTransferrableInWei, address _aRecipient);
    event LogTransferApproved(uint _uiId, uint _uiTransferrableInWei, address _aRecipient);
    event LogTransferExecuted(uint _uiId, uint _uiTransferrableInWei, address _aRecipient);
    
    // The number of approvals required set by the contract-owner
    uint                m_uiRequiredApprovals;
    
    // The addresses of the transfer approvers
    mapping(address => bool) m_mapAdministrators;
    
    // Requests currently awaiting approval
    TransferRequest[]   m_listRequests;

    // Requirement 2.2:     The contract creator should be able to input (2): The numbers of approvals required for a transfer, 
    //                      in the constructor. 
    constructor(uint _uiApprovals)
    {
        m_uiRequiredApprovals = _uiApprovals;
        RegisterAdmin(msg.sender);
    }
    
    // Requirement 2.1:     Contract creator should be able to input (1): the addressed of the owners.
    function RegisterAdmin(address _uiAdministrator) public __Mod_OwnerOnly 
    {
        m_mapAdministrators[_uiAdministrator] = true;
        
        emit LogAdministratorRegister(_uiAdministrator);
    }
    
    // Requirement 3:   Anyone of the owners should be able to create a transfer request. 
    //                  The creator of the transfer request will specify the amount and target addresses
    function RequestTransfer(uint _uiTransferrableInWei, address payable _aRecipient) public 
    __Mod_AdminOnly
    __Mod_Affordable(_uiTransferrableInWei)
    {
        require(_uiTransferrableInWei > 0, "Will not process empty transfers!");
        
        TransferRequest memory request = TransferRequest(m_listRequests.length, _uiTransferrableInWei, 0, _aRecipient);
        m_listRequests.push(request);
        
        emit LogTransferRequested(request.uiId, request.uiAmountInWei, request.aRecipient);
    }
    
    // Requirement 4:   Owners should be able to approve transfer requests
    // Requirement 5:   When a transfer request has the required approvals, the transfer should be sent.
    function ApproveTransfer(uint _uiIndex) public 
    __Mod_AdminOnly
    {
        require(_uiIndex < m_listRequests.length, "Invalid Index");
        require(address(this).balance >= m_listRequests[_uiIndex].uiAmountInWei, "Wallet does not have enough funds to process transaction");
        
        TransferRequest storage request = m_listRequests[_uiIndex];
        request.uiApprovals++;
        emit LogTransferRequested(request.uiId, request.uiAmountInWei, request.aRecipient);
        
        if(m_listRequests[_uiIndex].uiApprovals > m_uiRequiredApprovals)
        {
            request.aRecipient.transfer(request.uiAmountInWei);
            
            emit LogTransferExecuted(request.uiId, request.uiAmountInWei, request.aRecipient);
            
            delete m_listRequests[_uiIndex];
        }
    }
    
    function ViewRequest(uint _uiIndex) public view __Mod_AdminOnly returns(uint, address)
    {
        require(_uiIndex < m_listRequests.length, "Invalid Index");
        return (m_listRequests[_uiIndex].uiAmountInWei, m_listRequests[_uiIndex].aRecipient);
    }
}