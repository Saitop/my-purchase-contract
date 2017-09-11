pragma solidity ^0.4.11;


contract Purchase {
    uint public required;
    uint public value;
    address public seller;
    address public buyer;
    enum State { Created, Locked, Inactive }
    State public state;

    mapping(address => uint) traineeBalances;
    mapping(address => uint) traineeProgress;

    function getState() constant returns (State) {
        return state;
     }

    function Purchase(uint _required) payable {
        seller = msg.sender;
        value = msg.value / 2;
        required = _required;
        require((2 * value) == msg.value);
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SignOnLesson(address _from, uint _amount);
    event Refund(address _from, address _to, uint _amount);
    event Confirmation(address _from, address _to, uint _lesson);

    function abort() onlySeller inState(State.Created) {
        Aborted();
        state = State.Inactive;
        seller.transfer(this.balance);
    }

    function confirmPurchase() inState(State.Created) condition(msg.value == (2 * value)) payable {
        PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    function confirmReceived() onlyBuyer inState(State.Locked) {
        ItemReceived();
        state = State.Inactive;
        buyer.transfer(value);
        seller.transfer(this.balance);
    }

    function signOnLesson() payable {
        require(msg.value == 2 ether);
        traineeBalances[msg.sender] = msg.value;
        SignOnLesson(msg.sender, msg.value);
    }

    function refund(address _recipient) onlySeller {
        require(isTrainee(_recipient));
        require(isFinished(_recipient));
        _recipient.transfer(traineeBalances[_recipient]);
        Refund(msg.sender, _recipient, traineeBalances[_recipient]);
        traineeBalances[_recipient] = 0;
    }

    function isFinished(address _addr) constant returns (bool) {
        return traineeProgress[_addr] >= required;
    }

    function isTrainee(address _addr) constant returns (bool) {
        return traineeBalances[_addr] > 0;
    }

    function confirmOnce(address _recipient) onlySeller {
        require(isTrainee(_recipient));
        traineeProgress[_recipient] = traineeProgress[_recipient] + 1;
        Confirmation(msg.sender, _recipient, traineeProgress[_recipient]);
    }

    function checkProgress() onlySeller constant returns (uint256) {
        return traineeProgress[msg.sender];
    }


}
