import {
  mintProfile,
  updateProfile,
  mintMaster,
  burnMaster,
  burnMetadata,
} from "./methods";

// Script Intialization code.
const main = async () => {
  if (process.argv[2] === undefined) {
    console.log("Please provide a command");
  } else {
    const command = process.argv[2];

    try {
      switch (command) {
        case "mintProfile":
          await mintProfile();
          break;
        case "updateProfile": // REQUIRED: Add the Profile ObjectID before calling
          await updateProfile(
            "",
            2 // CAUTION: New watch time should be higher than the previous one
          );
          break;
        case "mintMaster": // Can update the values before calling
          await mintMaster();
          break;
        case "burnMaster": // REQUIRED: Add the Master ObjectID before calling
          await burnMaster("");
          break;
        case "burnMetadata": // REQUIRED: Add the Metadata ObjectID before calling
          await burnMetadata("");
          break;
        default:
          console.log("Invalid command");
          break;
      }
    } catch (e) {
      console.error("Command Failed:", e);
    }
  }
};

main();
