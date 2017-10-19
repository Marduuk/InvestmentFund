pragma solidity ^0.4.11;

contract Fund {
    uint startDate;

    uint endDate;

    uint totalPrizePool;

    uint nextCampaignId;

    uint reprocessLock;

    uint totalPenalty;

    address owner;

    uint numberOfCycles;

    uint oneCycle;

    uint onePayment;

    uint penalty;

    function Fund(){
        startDate = now;
        endDate = now + 9 minutes;
        reprocessLock = 0;
        owner = msg.sender;
        totalPrizePool = 0;
        numberOfCycles = 3;
        oneCycle = 3 minutes;
        onePayment = 0.1 ether;
        penalty = 0.02 ether;
    }

    mapping (address => uint) phoneBook;

    mapping (uint => Payment) payment;

    mapping (address => uint) worthy;

    struct Payment {
    uint amount;
    uint dateOfPayment;
    uint paymentsCount;
    address payOutAddr;
    }

    event paymentAccepted(address payoutAddress, address sender, uint dateOfTransaction);

    event enrolled(address payoutAddress, address sender, uint dateOfTransaction);

    event checker(address adr, uint amount, uint date, int paycount);
    modifier validateIfContractOpen(){if (startDate + oneCycle < now) revert();
        _;}
    modifier validateIfAlreadyExist(address payOutAddr){if (phoneBook[payOutAddr] != 0) revert();
        _;}
    modifier validateMsg(){if (msg.value != onePayment) revert();
        _;}
    modifier validatePaymentCountAndDate(address payOutAddr){if (payment[phoneBook[payOutAddr]].paymentsCount == numberOfCycles ||
    (now - startDate / oneCycle) == payment[phoneBook[payOutAddr]].paymentsCount) revert();
        _;}
    modifier checkIfenrolled(address payOutAddr){if (payment[phoneBook[payOutAddr]].paymentsCount < 1) revert();
        _;}
    modifier validateIfEnded(){if ((endDate + oneCycle) > now) revert();
        _;}
    modifier validateLock(){if (reprocessLock == 1) revert();
        _;}
    modifier isWorth(address payOutAddress){if (worthy[payOutAddress] == 0) revert();
        _;}
    modifier checkReprocessLock(){if (reprocessLock != 1) revert();
        _;}
    modifier isFullfilled(address payOutAddress, uint inHowManyRates){if ((worthy[payOutAddress] + inHowManyRates - 1) >= numberOfCycles + 1) revert();
        _;}
    modifier Ifzero(uint inHowManyRates){if (inHowManyRates == 0) revert();
        _;}

    modifier checkFee(address payOutAddr){
        uint lifeCycle = now - startDate;

        uint cycleOfContract = lifeCycle / oneCycle;
        uint begin = oneCycle * cycleOfContract;
        uint end = begin + oneCycle;

        int notPayedCycles = int(cycleOfContract - payment[phoneBook[payOutAddr]].paymentsCount);

        if (lifeCycle > begin && lifeCycle < end) {

            uint semiTotalFee = penalty * uint(notPayedCycles) + (onePayment * uint(notPayedCycles));
            uint totalFee = onePayment + semiTotalFee;

            if (msg.value != totalFee) {
                revert();
            }
            _;
        }
        else {
            revert();
            _;
        }
    }

    function calculateFee(address payOutAddr) returns (uint){
        uint lifeCycle = now - startDate;
        uint cycleOfContract = lifeCycle / oneCycle;
        int notPayedCycles = int(cycleOfContract - payment[phoneBook[payOutAddr]].paymentsCount);

        uint semiTotalFee = penalty * uint(notPayedCycles) + (onePayment * uint(notPayedCycles));
        return onePayment + semiTotalFee;
    }

    function enroll(address payOutAddr) payable
    validateMsg()
    validateIfContractOpen()
    validateIfAlreadyExist(payOutAddr)
    {
        phoneBook[payOutAddr] = nextCampaignId;

        payment[phoneBook[payOutAddr]].payOutAddr = payOutAddr;
        payment[phoneBook[payOutAddr]].amount += msg.value;
        payment[phoneBook[payOutAddr]].dateOfPayment = now;
        payment[phoneBook[payOutAddr]].paymentsCount += 1;

        enrolled(payOutAddr, msg.sender, now);

        nextCampaignId++;

    }

    function deposit(address payOutAddr) payable
    checkFee(payOutAddr)
    validatePaymentCountAndDate(payOutAddr)
    {
        payment[phoneBook[payOutAddr]].amount += msg.value;
        payment[phoneBook[payOutAddr]].dateOfPayment = now;
        uint moneyWithoutFee = msg.value - (penalty * (((((now - startDate) / oneCycle) - payment[phoneBook[payOutAddr]].paymentsCount))));
        totalPenalty += (penalty * (((((now - startDate) / oneCycle) - payment[phoneBook[payOutAddr]].paymentsCount))));
        payment[phoneBook[payOutAddr]].paymentsCount += moneyWithoutFee / onePayment;
        paymentAccepted(payment[phoneBook[payOutAddr]].payOutAddr, msg.sender, now);
    }

    function reproccess()
    validateIfEnded()
    validateLock()
    {
        uint totalParticipants = 0;
        uint participantsNotWorthy = 0;
        uint prizePool;
        while (payment[totalParticipants].paymentsCount != 0) {
            if (payment[totalParticipants].paymentsCount != numberOfCycles) {
                prizePool += payment[totalParticipants].amount;
                payment[totalParticipants].amount = 0;
                participantsNotWorthy++;
            }
            if (payment[totalParticipants].paymentsCount == numberOfCycles) {
                worthy[payment[totalParticipants].payOutAddr] = 1;
            }
            totalParticipants++;
        }
        reprocessLock = 1;
        totalPrizePool = (prizePool + totalPenalty / (totalParticipants - participantsNotWorthy)) / numberOfCycles;
    }

    function withDraw(address payOutAddress, uint inHowManyRates)
    isWorth(payOutAddress)
    isFullfilled(payOutAddress, inHowManyRates)
    checkReprocessLock()
    Ifzero(inHowManyRates)
    {
        payOutAddress.transfer(inHowManyRates*(onePayment + totalPrizePool));
        worthy[payOutAddress] += inHowManyRates;
    }

    modifier theDAOhack(){if (msg.sender != owner) revert();
        _;}
    function die()
    theDAOhack()
    {
        msg.sender.transfer(this.balance);
    }
}


















