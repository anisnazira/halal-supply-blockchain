// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HalalSupplyChain {

    // Roles
    address public admin;

    bytes32 public constant ROLE_FARM_SUPPLIER     = keccak256("FARM_SUPPLIER");
    bytes32 public constant ROLE_PROCESSING_PLANT  = keccak256("PROCESSING_PLANT");
    bytes32 public constant ROLE_JAKIM             = keccak256("JAKIM");
    bytes32 public constant ROLE_LOGISTICS         = keccak256("LOGISTICS");
    bytes32 public constant ROLE_RETAILER          = keccak256("RETAILER");

    mapping(address => mapping(bytes32 => bool)) private roles;

    event RoleAssigned(address indexed account, bytes32 role);
    event RoleRevoked(address indexed account, bytes32 role);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(roles[msg.sender][role], "Caller missing role");
        _;
    }

    constructor() {
        admin = msg.sender;

        roles[msg.sender][ROLE_FARM_SUPPLIER] = true;
        roles[msg.sender][ROLE_JAKIM] = true;

        emit RoleAssigned(msg.sender, ROLE_FARM_SUPPLIER);
        emit RoleAssigned(msg.sender, ROLE_JAKIM);
    }

    // Role Management
    function assignRole(address account, bytes32 role) external onlyAdmin {
        roles[account][role] = true;
        emit RoleAssigned(account, role);
    }

    function revokeRole(address account, bytes32 role) external onlyAdmin {
        roles[account][role] = false;
        emit RoleRevoked(account, role);
    }

    function hasRole(address account, bytes32 role) public view returns (bool) {
        return roles[account][role];
    }

    // Supply Chain Logic
    enum Stage { Raw, Slaughtered, Processed, Packaged, Shipped, Delivered }

    struct Batch {
        uint256 id;
        string details;
        Stage currentStage;
        string status;
        uint256 createdAt;
        bool exists;
    }

    struct HalalCertificate {
        bool exists;
        bytes32 certHash;
        uint256 issuedAt;
    }

    struct Shipment {
        string location;
        uint256 timestamp;
        string status;
    }

    uint256 public batchCounter;
    mapping(uint256 => Batch) private batches;
    mapping(uint256 => HalalCertificate) private halalCertificates;
    mapping(uint256 => Shipment[]) private batchShipments;

    // Events
    event BatchCreated(uint256 batchId, string details, uint256 timestamp);
    event StageUpdated(uint256 batchId, Stage newStage, uint256 timestamp);
    event HalalCertified(uint256 batchId, bytes32 certHash, uint256 timestamp);
    event ShipmentRecorded(uint256 batchId, string location, string status, uint256 timestamp);
    event BatchReceived(uint256 batchId, uint256 timestamp);


    // Batch Lifecycle
    function createBatch(string calldata details)
        external
        onlyRole(ROLE_FARM_SUPPLIER)
    {
        batchCounter++;

        batches[batchCounter] = Batch({
            id: batchCounter,
            details: details,
            currentStage: Stage.Raw,
            status: "Raw Chicken Registered",
            createdAt: block.timestamp,
            exists: true
        });

        emit BatchCreated(batchCounter, details, block.timestamp);
    }

    function updateStage(uint256 batchId, Stage newStage)
        external
        onlyRole(ROLE_PROCESSING_PLANT)
    {
        require(batches[batchId].exists, "Batch does not exist");

        Batch storage batch = batches[batchId];

        require(
            (newStage == Stage.Slaughtered && batch.currentStage == Stage.Raw) ||
            (newStage == Stage.Processed && batch.currentStage == Stage.Slaughtered) ||
            (newStage == Stage.Packaged && batch.currentStage == Stage.Processed),
            "Invalid stage transition"
        );

        batch.currentStage = newStage;
        batch.status = getStageString(newStage);

        emit StageUpdated(batchId, newStage, block.timestamp);
    }

    function certifyHalal(uint256 batchId, bytes32 certHash)
        external
        onlyRole(ROLE_JAKIM)
    {
        require(batches[batchId].exists, "Batch does not exist");
        require(!halalCertificates[batchId].exists, "Already certified");

        halalCertificates[batchId] = HalalCertificate({
            exists: true,
            certHash: certHash,
            issuedAt: block.timestamp
        });

        emit HalalCertified(batchId, certHash, block.timestamp);
    }

    // Shipment updates stage automatically
    function recordShipment(
        uint256 batchId,
        string calldata location,
        string calldata status
    )
        external
        onlyRole(ROLE_LOGISTICS)
    {
        require(batches[batchId].exists, "Batch does not exist");
        require(
            batches[batchId].currentStage == Stage.Packaged,
            "Batch must be packaged before shipping"
        );

        batchShipments[batchId].push(Shipment({
            location: location,
            timestamp: block.timestamp,
            status: status
        }));

        batches[batchId].currentStage = Stage.Shipped;
        batches[batchId].status = "Shipped";

        emit ShipmentRecorded(batchId, location, status, block.timestamp);
    }

    //  Retailer only receives shipped batch
    function confirmReceived(uint256 batchId)
        external
        onlyRole(ROLE_RETAILER)
    {
        require(batches[batchId].exists, "Batch does not exist");
        require(
            batches[batchId].currentStage == Stage.Shipped,
            "Batch must be shipped before delivery"
        );

        batches[batchId].currentStage = Stage.Delivered;
        batches[batchId].status = "Delivered to Retailer";

        emit BatchReceived(batchId, block.timestamp);
    }


    // Views (Public Transparency)
    function getBatch(uint256 batchId)
        external
        view
        returns (
            uint256 id,
            string memory details,
            string memory stage,
            string memory status,
            uint256 createdAt,
            bytes32 certHash,
            uint256 certifiedAt
        )
    {
        require(batches[batchId].exists, "Batch does not exist");

        Batch storage b = batches[batchId];
        HalalCertificate storage c = halalCertificates[batchId];

        return (
            b.id,
            b.details,
            getStageString(b.currentStage),
            b.status,
            b.createdAt,
            c.certHash,
            c.issuedAt
        );
    }

    function getShipmentHistory(uint256 batchId)
        external
        view
        returns (Shipment[] memory)
    {
        require(batches[batchId].exists, "Batch does not exist");
        return batchShipments[batchId];
    }

    // Helper
    function getStageString(Stage stage)
        public
        pure
        returns (string memory)
    {
        if (stage == Stage.Raw) return "Raw Chicken Registered";
        if (stage == Stage.Slaughtered) return "Slaughtered";
        if (stage == Stage.Processed) return "Processed";
        if (stage == Stage.Packaged) return "Packaged";
        if (stage == Stage.Shipped) return "Shipped";
        return "Delivered";
    }
}
