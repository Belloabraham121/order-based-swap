import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const OrderSwapContractModule = buildModule("OrderSwapContractModule", (m) => {
 
  const initialOwner = "0x28482B1279E442f49eE76351801232D58f341CB9"

  const OrderSwapContract = m.contract("OrderSwapContract", [initialOwner]);

  return { OrderSwapContract };
});

export default OrderSwapContractModule;
