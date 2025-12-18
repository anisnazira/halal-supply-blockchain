# halal-supply-chain
A Solidity smart contract implementing a halal-certified poultry supply chain. This project tracks the lifecycle of chicken batches from farm suppliers to processing plants, logistics, and retailers. It includes role-based access control for farm suppliers, processing plants, Jakim (halal certification authority), logistics, and retailers. Key features include batch creation, stage updates, halal certification, shipment recording, and delivery confirmation, ensuring transparency and traceability throughout the supply chain.



3.4	Core Functions
•	assignRole() – Assigns specific supply chain roles to blockchain addresses
•	revokeRole() – Revokes assigned roles from addresses
•	createBatch() – Creates a new chicken nugget batch at the farm supplier stage
•	updateStage() – Updates the batch stage during slaughtering, processing, and packaging by the processing plant.
•	certifyHalal() – Issues halal certification for a batch by JAKIM.
•	recordShipment() – Records shipment details and updates the batch stage to shipped
•	confirmReceived() – Confirms receipt of shipped batches by retailers and updates the stage to delivered
•	getBatch() – Retrieves batch details, current stage, status, and halal certification data
•	getShipmentHistory() – Retrieves shipment tracking history

3.5	Events
•	RoleAssigned – Triggered when a role is assigned to an address
•	RoleRevoked – Triggered when a role is revoked
•	BatchCreated – Triggered when a new batch is created
•	StageUpdated – Triggered when a batch stage is updated
•	HalalCertified – Triggered when halal certification is issued
•	ShipmentRecorded – Triggered when shipment details are recorded
•	BatchReceived – Triggered when the retailer confirms receipt of a batch

