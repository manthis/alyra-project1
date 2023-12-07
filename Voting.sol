// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    event VoteIsOver();

    uint private winningProposalId;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    mapping (address => Voter) voters;

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered == true, "You are not a valid voter!");
        _;
    }

    modifier VoteOnce() {
        require(voters[msg.sender].hasVoted == false, "You already voted!");
        _;
    }

    struct Proposal {
        uint id;
        string description;
        uint voteCount;
    }

    Proposal[] proposals;
    uint proposalId = 0;

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    WorkflowStatus private currentVoteState;    

    modifier votesTallied() {
        require(currentVoteState == WorkflowStatus.VotesTallied, "Votes need to be tallied in order to do that.");
        _;
    }

    modifier votesNotTallied() {
        require(currentVoteState != WorkflowStatus.VotesTallied, "Votes should not be tallied in order to do that.");
        _;
    }

    modifier registeringVoters() {
        require(currentVoteState == WorkflowStatus.RegisteringVoters, "You cannot register voters.");
        _;
    }

    modifier registeringProposals() {
        require(currentVoteState == WorkflowStatus.ProposalsRegistrationStarted, "You cannot register proposals.");
        _;
    }

    modifier votingProposals() {
        require(currentVoteState == WorkflowStatus.VotingSessionStarted, "You cannot vote proposals.");
        _;
    }



    constructor() Ownable(msg.sender) {
        currentVoteState = WorkflowStatus.RegisteringVoters;
    }


    function getVoteStep() external view returns (WorkflowStatus) {
        return currentVoteState;
    }

    function nextVoteStep() external onlyOwner votesNotTallied {
        WorkflowStatus previousState = currentVoteState;
        currentVoteState = WorkflowStatus(uint(currentVoteState) + 1);
        emit WorkflowStatusChange(previousState, currentVoteState);
    }
    
    function restartVote() external onlyOwner votesTallied {
        currentVoteState = WorkflowStatus.RegisteringVoters;
    }

    function addVoter(address _address) external onlyOwner registeringVoters {
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function addProposal(string calldata _description) external onlyVoters registeringProposals {
        proposals.push(Proposal(proposalId, _description, 0));
        emit ProposalRegistered(proposalId++);
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function vote(uint _proposalId) external onlyVoters votingProposals VoteOnce {
        proposals[_proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposals[_proposalId].id;

        emit Voted(msg.sender, voters[msg.sender].votedProposalId);
    }

    function getWinner() external votesTallied returns (Proposal memory) {

    }
}