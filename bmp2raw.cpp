// bmp2raw.cpp

#include <iostream>
#include <fstream>
#include <vector>
#include <array>
#include <cstdint>
#include <string>
#include <cstring>
#include <filesystem>

// Structure to represent a file entry in the directory file
struct FileEntry {
    char FileName[8];
    char FileSuff[3];
    uint8_t FileOffs[3];
};

// Structure to represent the BMP header in the game files
struct BMPHeader {
    char Unknown1[2];
    uint16_t Unknown2;
    uint16_t Width;
    uint16_t Height;
};

//
// Function to compute the file offset from FileOffs
//
uint32_t GetFileOffset(const FileEntry& fe) {
    return fe.FileOffs[0] + (fe.FileOffs[1] << 8) + (fe.FileOffs[2] << 16);
}

//
// Function to read the directory file and store the entries
//
std::vector<FileEntry> readDirectoryFile(const std::string& dirFileName) {
    std::ifstream dirFile(dirFileName, std::ios::binary);
    if (!dirFile) {
        std::cerr << "Failed to open directory file: " << dirFileName << std::endl;
        exit(1);
    }
    std::vector<FileEntry> entries;
    FileEntry fe;
    while (dirFile.read(reinterpret_cast<char*>(&fe), sizeof(FileEntry))) {
        entries.push_back(fe);
    }
    return entries;
}

//
// Function to read a 16-bit little-endian value from a file
//
uint16_t readUInt16LE(std::ifstream& file) {
    uint8_t bytes[2];
    file.read(reinterpret_cast<char*>(bytes), 2);
    return bytes[0] | (bytes[1] << 8);
}

//
// Function to get the file name from a FileEntry
//
std::string getFileName(const FileEntry& fe) {
    std::string fname;
    for (int i = 0; i < 8; ++i) {
        if (fe.FileName[i] == '\0') break;
        fname += fe.FileName[i];
    }
    fname += '.';
    for (int i = 0; i < 3; ++i) {
        if (fe.FileSuff[i] == '\0') break;
        fname += fe.FileSuff[i];
    }
    return fname;
}

//
// Function to decompress data using the LZSS algorithm
//
std::vector<uint8_t> decompressLZSS(std::ifstream& dataFile, uint32_t offset, uint32_t compSize, uint32_t uncompSize) {
    const int N = 4096;
    const int THRESHOLD = 2;
    std::vector<uint8_t> outBuffer;
    outBuffer.reserve(uncompSize);
    std::vector<uint8_t> history(N, 0);
    int bufWrtPtr = 0;
    dataFile.seekg(offset);
    uint32_t bytesRead = 0;
    uint32_t bytesWritten = 0;
    while (bytesRead < compSize) {
        uint8_t tag;
        dataFile.read(reinterpret_cast<char*>(&tag), 1);
        bytesRead++;
        for (int i = 0; i < 8 && bytesRead < compSize; ++i) {
            if ((tag & 1) == 0 && (bytesRead + 1 < compSize)) {
                uint8_t lengthByte, offsetByte;
                dataFile.read(reinterpret_cast<char*>(&lengthByte), 1);
                dataFile.read(reinterpret_cast<char*>(&offsetByte), 1);
                bytesRead += 2;
                uint16_t offset = (offsetByte << 4) | (lengthByte >> 4);
                uint16_t length = (lengthByte & 0x0F) + THRESHOLD;
                if (offset != 0) {
                    int bufReadPtr = (bufWrtPtr - offset + N) % N;
                    for (int j = 0; j <= length; ++j) {
                        uint8_t b = history[(bufReadPtr + j) % N];
                        history[bufWrtPtr] = b;
                        outBuffer.push_back(b);
                        bytesWritten++;
                        bufWrtPtr = (bufWrtPtr + 1) % N;
                    }
                }
            } else if (bytesRead < compSize) {
                uint8_t b;
                dataFile.read(reinterpret_cast<char*>(&b), 1);
                bytesRead++;
                outBuffer.push_back(b);
                history[bufWrtPtr] = b;
                bytesWritten++;
                bufWrtPtr = (bufWrtPtr + 1) % N;
            }
            tag >>= 1;
        }
    }
    if (bytesWritten != uncompSize) {
        std::cerr << "Warning: decompressed size does not match expected size" << std::endl;
    }
    return outBuffer;
}

//
// Function to process the palette data
//
std::vector<std::array<uint8_t, 3>> processPalette(const std::vector<uint8_t>& paletteData) {
    std::vector<std::array<uint8_t, 3>> palette(256);
    for (int i = 0; i < 256; ++i) {
        uint8_t b = paletteData[i * 3 + 0];
        uint8_t g = paletteData[i * 3 + 1];
        uint8_t r = paletteData[i * 3 + 2];
        // Expand values and swap R/B
        uint8_t j = r;
        r = b << 2;
        g = g << 2;
        b = j << 2;
        palette[i] = { r, g, b };
    }
    return palette;
}

//
// Function to process BMP data and convert it to raw RGB data
//
std::vector<uint8_t> processBMP(const std::vector<uint8_t>& bmpData, const std::vector<std::array<uint8_t, 3>>& palette) {
    if (bmpData.size() < 8) {
        std::cerr << "Invalid BMP data." << std::endl;
        return {};
    }
    BMPHeader header;
    memcpy(&header, bmpData.data(), 8);
    uint16_t width = header.Width;
    uint16_t height = header.Height;
    size_t expectedSize = 8 + width * height;
    if (bmpData.size() != expectedSize) {
        std::cerr << "Invalid BMP data size." << std::endl;
        return {};
    }
    const uint8_t* imageData = bmpData.data() + 8;
    std::vector<uint8_t> rgbData;
    rgbData.reserve(width * height * 3);
    for (size_t i = 0; i < width * height; ++i) {
        uint8_t index = imageData[i];
        const auto& color = palette[index];
        rgbData.push_back(color[0]); // R
        rgbData.push_back(color[1]); // G
        rgbData.push_back(color[2]); // B
    }
    return rgbData;
}

//
// Main Entrypoint
//
int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: extractor data.dir data.001 palette.pal" << std::endl;
        return 1;
    }
    std::string dirFileName = argv[1];
    std::string dataFileName = argv[2];
    std::string paletteFileName = argv[3];

    auto entries = readDirectoryFile(dirFileName);
    std::ifstream dataFile(dataFileName, std::ios::binary);
    if (!dataFile) {
        std::cerr << "Failed to open data file: " << dataFileName << std::endl;
        return 1;
    }
    std::vector<uint8_t> paletteData;
    std::ifstream paletteFile(paletteFileName, std::ios::binary);
    if (paletteFile) {
        paletteData.assign((std::istreambuf_iterator<char>(paletteFile)), std::istreambuf_iterator<char>());
        if (paletteData.size() < 256 * 3) {
            std::cerr << "Invalid palette file." << std::endl;
            return 1;
        }
    } else {
        std::cerr << "Failed to open palette file: " << paletteFileName << std::endl;
        return 1;
    }
    auto palette = processPalette(paletteData);

    for (const auto& fe : entries) {
        std::string fname = getFileName(fe);
        uint32_t foffs = GetFileOffset(fe);
        dataFile.seekg(foffs);
        uint16_t uncompSize = readUInt16LE(dataFile);
        uint16_t compSize = readUInt16LE(dataFile);
        uint32_t dataOffset = dataFile.tellg();
        std::vector<uint8_t> decompressedData = decompressLZSS(dataFile, dataOffset, compSize, uncompSize);
        std::string extension = fname.substr(fname.find_last_of('.') + 1);
        if (extension == "BMP" || extension == "bmp") {
            std::vector<uint8_t> rgbData = processBMP(decompressedData, palette);
            std::string outFileName = fname + ".raw";
            std::ofstream outFile(outFileName, std::ios::binary);
            if (outFile) {
                outFile.write(reinterpret_cast<char*>(rgbData.data()), rgbData.size());
                std::cout << "Extracted " << outFileName << std::endl;
            } else {
                std::cerr << "Failed to open output file: " << outFileName << std::endl;
            }
        }
    }
    return 0;
}