// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
*   @title  Voting contrat: this contract allow a whitelist of voters to vote for their favorite proposition.
*   @author Maxime AUBURTIN
*   @notice You can use this contract for only the most basic simulation
*   @dev    All corner cases of a vote are not handled in this version also there is no egality, the first vote which has
*           the maximum voices wins.
*/
contract Voting is Ownable {

    /**
    * Events
    */
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    /**
    * Id of the winning proposal
    */
    uint private winningProposalId;

    /**
    * Voter structure
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
    * Voters whitelist
    */
    mapping (address => Voter) voters;

    /**
    * Modifier to allow only voters
    */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered == true, "You are not a valid voter!");
        _;
    }

    /**
    * Modifier to only allow a unique vote
    */
    modifier VoteOnce() {
        require(voters[msg.sender].hasVoted == false, "You already voted!");
        _;
    }

    /**
    * Proposal structure
    */
    struct Proposal {
        uint id;
        string description;
        uint voteCount;
    }

    /**
    * List of proposals and proposal counter to create proposal id
    */
    Proposal[] proposals;
    uint proposalIdCounter = 0;

    /**
    * Steps of the state machine
    */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    /**
    * Current state machine state and modifiers for the state machine
    */
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

    /**
    * Contract code
    */

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
    
    function addVoter(address _address) external onlyOwner registeringVoters {
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function addProposal(string calldata _description) external onlyVoters registeringProposals {
        proposals.push(Proposal(proposalIdCounter, _description, 0));
        emit ProposalRegistered(proposalIdCounter++);
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function voteForProposition(uint _proposalId) external onlyVoters votingProposals VoteOnce {
        proposals[_proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposals[_proposalId].id;

        emit Voted(msg.sender, voters[msg.sender].votedProposalId);
    }

    function getWinner() external votesTallied returns (Proposal memory) {
        uint maxVoteCount = 0;
        for (uint i=0; i<proposals.length; i++) {
            Proposal memory proposal = proposals[i];
            if (proposal.voteCount > maxVoteCount) {
                winningProposalId = proposal.id;
                maxVoteCount = proposal.voteCount;
            }
        }

        return proposals[winningProposalId];
    }
}