const pinataSDK = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");

// Pinata configuration
PINATA_API_KEY = process.env.PINATA_API_KEY;
PINATA_API_SECRET = process.env.PINATA_API_SECRET;
const pinata = pinataSDK(PINATA_API_KEY, PINATA_API_SECRET);

const storeImages = async (pathOfImages) => {
  const fullImagesPath = path.resolve(pathOfImages);
  const files = fs.readdirSync(fullImagesPath);
  require("dotenv").config();
  console.log(files);

  let responses = [];

  console.log("files upload is started ------------------------------");
  for (fileIndex in files) {
    const readableFiles = fs.createReadStream(
      `${fullImagesPath}/${files[fileIndex]}`
    );
    try {
      const response = await pinata.pinFileToIPFS(readableFiles);
      responses.push(response);
    } catch (error) {
      console.log("There is an error while uploading image", error);
    }
  }

  console.log("files upload done---------------------");
  return { responses, files };
};

// Store the meta data
const storeMetaData = async (metadata) => {
  try {
    const response = await pinata.pinJSONToIPFS(metadata);
    return response;
  } catch (error) {
    console.log("You are in catch of storeMetadata ", error);
  }
  return null;
};

module.exports = { storeImages, storeMetaData };
