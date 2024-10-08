// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
*   @title  Voting contrat: this contract allow a whitelist of voters to vote for their favorite proposition.
*   @author Maxime AUBURTIN
*/
contract VotingPlus is Ownable {

    /**
    * Events
    */
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    event VoteEquality(string message);

    /**
    * Id of the winning proposal
    */
    int private winningProposalId = -1;

    /**
    * Array containing the winner or the winners in case of equality
    */
    Proposal[] winners;
        

    /**
    * Voter structure
    */
    struct Voter {
        bool isRegistered;
        uint hasVoted;
        uint nbVotes;
        uint[] votedProposalIds;
    }
  

    /**
    * Voters whitelist and array to store keys
    */
    mapping (address => Voter) voters;
    address[] votersKeys;

    // Some counters
    uint votersNumber = 0;
    uint atLeastOneVote = 0;

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
    modifier voteAsManyTimesAsYoureAllowedTo() {
        require(voters[msg.sender].hasVoted < voters[msg.sender].nbVotes, "You already used all your votes!");
        _;
    }

    /**
    * Proposal structure
    */
    struct Proposal {
        uint id;
        string description;
        uint voteCount;
        uint lastVoteTimestamp;
    }

    /**
    * List of proposals and proposal counter to create proposal id
    */
    Proposal[] proposals;
    uint proposalIdCounter = 0; // used to create proposal Ids

    /**
    * Steps of the state machine
    */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistration,
        VotingSession,
        VotesTallied
    }
    
    /**
    * Current state machine state and modifiers for the state machine
    */
    WorkflowStatus private currentVoteState;    

    modifier votesTallied() { // This modifier ensure we are at the last step of the state machine
        require(currentVoteState == WorkflowStatus.VotesTallied, "Votes need to be tallied in order to perform this operation");
        _;
    }

    modifier votesNotTallied() { // This modifier ensure we are not at the last step of the workflow
        require(currentVoteState != WorkflowStatus.VotesTallied, "Votes have to be tallied. It is over. There is no next step!");
        _;
    }

    modifier registeringVoters() { // This modifier ensure we are presently registering voters
        require(currentVoteState == WorkflowStatus.RegisteringVoters, "You cannot register voters");
        _;
    }

    modifier registeringProposals() { // This modifier ensure we are presently registering propositions
        require(currentVoteState == WorkflowStatus.ProposalsRegistration, "You cannot register proposals");
        _;
    }

    modifier votingProposals() { // This modifier ensure we are presently voting propositions
        require(currentVoteState == WorkflowStatus.VotingSession, "You cannot vote proposals");
        _;
    }

    modifier votersRegistered(uint nbVoters) { // This modifier ensure we have at least nbVoters voters before moving to the next state of the state machine
        if (currentVoteState == WorkflowStatus.RegisteringVoters) {
            require(votersNumber >= nbVoters, "A minimum number of voters are required to continue");
        }
        _;
    }

    modifier proposalRegistered(uint nbProposals) { // This modifier ensure we have at least nbProposals propositions before moving to the next state of the state machine
        if (currentVoteState == WorkflowStatus.ProposalsRegistration) {
            require(proposalIdCounter >= nbProposals, "A minimum number of propositions are required to continue");
        }
        _;
    }

    modifier voteRegistered(uint nbVote) { // This modifier ensure we have at least nbVote votes before moving to the next state of the state machine
        if (currentVoteState == WorkflowStatus.VotingSession) {
            require(atLeastOneVote >= nbVote, "A minimum number of votes are required to continue");
        }
        _;
    }


    /**===================================================================================================================================================================
    * Smart Contract methods
    ***=================================================================================================================================================================*/

    constructor() Ownable(msg.sender) {
        currentVoteState = WorkflowStatus.RegisteringVoters;
    }

    /**
    *   @notice Returns the current step of the state machine
    */
    function getCurrentVoteStep() external view returns (WorkflowStatus) {
        return currentVoteState;
    }

    /**
    *   @notice Move the state machine to its next state if constraints brought by modifiers are fullfilled
    */
    function nextVoteStep() external onlyOwner votersRegistered(3) proposalRegistered(2) voteRegistered(1) votesNotTallied {
        WorkflowStatus previousState = currentVoteState;
        currentVoteState = WorkflowStatus(uint(currentVoteState) + 1);
        emit WorkflowStatusChange(previousState, currentVoteState);
    }

    /**
    *   @notice this external addVoter function allows to add a new voter to the whitelist
    */
    function addVoter(address _address) external onlyOwner registeringVoters {
        require(_address != owner(), "Owner cannot vote!");
        require(voters[_address].isRegistered == false, "Voter already registered!");

        addVoterInternal(_address);
        emit VoterRegistered(_address);
    }

    /**
    *   @notice this internal addVoter function allows to add a new voter to the whitelist 
    */
    function addVoterInternal(address _address) internal {
        voters[_address].hasVoted = 0;
        voters[_address].nbVotes = 1;
        voters[_address].isRegistered = true;
        registerVoterKey(_address);
        
        votersNumber++;
    }

    /**
    *   @notice Internal function to register voters' keys when adding a new voter
    */
    function registerVoterKey(address _voterKey) internal {
        bool hasKeyBeenFound = false;
        for (uint i=0; i<votersKeys.length; i++) {
            if (votersKeys[i] == _voterKey) {
                hasKeyBeenFound = true;
            }
        }
        if (hasKeyBeenFound == false) {
            votersKeys.push(_voterKey);
        }
    }

    /**
    *   @notice This method allows a voter to delegate its vote to an existing or to a new voter
    *   @param _delegate The adresse to delegate the vote to
    */
    function delegateVote(address _delegate) onlyVoters registeringVoters external {

        // In the case our delegate is already registered as a valid voter
        if (voters[_delegate].isRegistered) {
            // We give him an extra voice as a delegate
            voters[_delegate].nbVotes++;
        } else {
            // We add a valid voter to the list
            addVoterInternal(_delegate);
        }

        // We delete our current voter
        deleteVoter(msg.sender);

    }

    /**
    *   @notice This internal method allows to delete a voter
    */
    function deleteVoter(address _address) internal {
        voters[_address].isRegistered = false;
        voters[_address].hasVoted = 0;
        voters[_address].nbVotes = 1;
        delete voters[_address].votedProposalIds;

        for (uint i=0; i<votersKeys.length; i++) {
            if (votersKeys[i] == _address) {
                votersKeys.pop();
            }
        }
    }

    /**
    *   @notice This method allows to create a new proposition
    *   @param _description The content of the proposition to be voted
    */
    function addProposal(string calldata _description) external onlyVoters registeringProposals {
        proposals.push(Proposal(proposalIdCounter, _description, 0, 0));
        emit ProposalRegistered(proposalIdCounter++);
    }

    /**
    *   @notice This method allows to list all registered propositions
    *   @return An array of proposals
    */
    function listProposals() external view returns (Proposal[] memory) {
        require(proposals.length > 0, "There are no propositions registered yet!");
        return proposals;
    }

    /**
    *   @notice This method allows to vote for a proposition by its id
    *   @param _proposalId The if of the proposition to vote for
    */
    function voteForProposition(uint _proposalId) external onlyVoters votingProposals voteAsManyTimesAsYoureAllowedTo {
        require(_proposalId >= 0 && _proposalId < proposals.length, "The proposition you're voting for does not exist!");

        proposals[_proposalId].voteCount++; // We increment the proposition votes count
        proposals[_proposalId].lastVoteTimestamp = block.timestamp; // We keep the timestamp of the vote

        // We increment the number of votes of the voter and we memorize the proposition he voted for
        voters[msg.sender].hasVoted++;
        voters[msg.sender].votedProposalIds.push(proposals[_proposalId].id);

        atLeastOneVote++;
        emit Voted(msg.sender, proposals[_proposalId].id);

    }

    /**
    *   @notice This method will tail the Votes and return an array containing one or more winners. In case there is only one winner
    *           its id will be recorded as the winning proposition in winningProposalId which can be retrieved through the getWinner
    *           function.
    */
    function tailVotes() external votesTallied returns (Proposal[] memory) {

        uint maxVoteCount = 0;

        // We collect all the propositions with the biggest score
        for (uint i=0; i<proposals.length; i++) {
            Proposal memory proposal = proposals[i];
            if (proposal.voteCount > maxVoteCount) {
                delete winners;
                winners.push(proposal);
                maxVoteCount = proposal.voteCount;
            } else if (proposal.voteCount == maxVoteCount) {
                winners.push(proposal);
            }
        }

        if (winners.length > 1 ) {
            emit VoteEquality("You must vote again for one of the propositions which qualified previously!");
        } else {
            winningProposalId = int(winners[0].id); // We record the id of the winning proposition
        }

        return winners;
    }

    /**
    *   @notice This method will solve a situation of equality between proposals by creating a voting session only for these 
    *           propositions which got the same number of votes. Vote will take the same shape until there is one unique winner.
    */
    function solveEqualityWithVote() external onlyOwner votesTallied {
        require(winners.length > 1, "There are no equality in results so we don't need to break the tie!");

        proposalIdCounter = winners.length;
        
        // We empty our proposals and replace them with the winners
        delete proposals;
        proposals = winners;

        // We reinitialize each proposition vote count
        for (uint i=0; i<proposals.length; i++) {
            proposals[i].voteCount = 0;
        }

        // We reinitialize each voters' vote
        for (uint i=0; i<votersKeys.length; i++) {
            voters[votersKeys[i]].hasVoted = 0;
            delete voters[votersKeys[i]].votedProposalIds;
        }
        
        // We rollback the state machine to VotingSession state
        currentVoteState = WorkflowStatus.VotingSession;
    }

    /**
    *   @notice This method will solve a situtation of equality between proposals by looking for the oldest voted proposition.
    *           It is this one which will be designated as the winner and its id stored in winningProposalId
    */
    function solveEqualityWithTimestamp() external onlyOwner votesTallied {
        require(winners.length > 1, "There are no equality in results so we don't need to break the tie!");

        uint smallestTimestamp = block.timestamp;
        Proposal memory winner;
        for(uint i=0; i<winners.length; i++) {
            if (winners[i].lastVoteTimestamp != 0 && winners[i].lastVoteTimestamp < smallestTimestamp) {
                winner = winners[i];
                smallestTimestamp = winner.lastVoteTimestamp;
            }
        }

        // We record the id of the winning proposition
        winningProposalId = int(winner.id);        
    }

    /**
    *   @notice This method allows to restart the whole voting session once votes are tallied
    */
    function restartVoteFromScratch() external votesTallied onlyOwner {

        // We rollback to the RegisteringVoters state of the state machine
        currentVoteState = WorkflowStatus.RegisteringVoters;

        // We erase all the propositions
        proposalIdCounter = 0;
        delete proposals;
        
        // We reinitiate counters
        votersNumber = 0;
        atLeastOneVote = 0;
        
        // We reinitiate the mapping of voters
        for (uint i=0; i<votersKeys.length; i++) {
            delete voters[votersKeys[i]];
        }

        // We delete memorized voters keys
        delete votersKeys;

        // We remove the winner id
        winningProposalId = -1;
    }

    /**
    *   @notice This method returns the winning proposition once votes have been tallied and equality issues solved
    */
    function getWinner() external view returns (int) {
        require(winningProposalId >=0, "There is no winning proposition yet!");
        return winningProposalId;
    }

}