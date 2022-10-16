const fs = require("fs");

async function main() {
  console.log("");

  //Leemos la dirección del contrato deployado y la reescribimos en el archivo currentTickbitContract.txt
  const bufferDeployTickbitContract = fs.readFileSync("./scripts/release/currentTickbitTicketContract.txt");
  const fileContentDeployTickbitContract = bufferDeployTickbitContract.toString();
  const addressTickbitTicketContract = fileContentDeployTickbitContract.slice(-43).slice(0, 42);
  fs.writeFileSync("./scripts/release/currentTickbitTicketContract.txt", addressTickbitTicketContract);

  //Cambiamos la dirección del contrato en el proyecto backoffice
  const bufferBackoffice = fs.readFileSync("../tickbit-backoffice/src/solidity/config.js");
  const fileContentBackoffice = bufferBackoffice.toString();
  const parteParaCambiar2 = fileContentBackoffice.split("\n")[1].split("\" : \"")[1].slice(0, 42);
  const newContract2 = fileContentBackoffice.replace(parteParaCambiar2, addressTickbitTicketContract);
  fs.writeFileSync("../tickbit-backoffice/src/solidity/config.js", newContract2);

  //Cambiamos la dirección del contrato en el proyecto web
  const bufferWeb = fs.readFileSync("../tickbit-web/src/solidity/config.js");
  const fileContentWeb = bufferWeb.toString();
  const parteParaCambiar3 = fileContentWeb.split("\n")[1].split("\" : \"")[1].slice(0, 42);
  const newContract3 = fileContentWeb.replace(parteParaCambiar3, addressTickbitTicketContract);
  fs.writeFileSync("../tickbit-web/src/solidity/config.js", newContract3);

	console.log("Dirección del contrato deployado TickbitTicket.sol cambiada correctamente");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
