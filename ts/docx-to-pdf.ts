#!/usr/bin/env bun

import { exec } from "child_process";
import path from "path";
import fs from "fs";
import os from "os";

/**
 * Create a temporary directory for libreoffice to write into.
 */
function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "docx-to-pdf-"));
}

/**
 * Ensure file path doesn't overwrite existing files.
 */
function getUniqueFilePath(filePath: string): string {
  if (!fs.existsSync(filePath)) return filePath;

  const dir = path.dirname(filePath);
  const ext = path.extname(filePath);
  const baseName = path.basename(filePath, ext);

  let counter = 1;
  let newPath: string;

  do {
    const suffix = counter.toString().padStart(2, "0");
    newPath = path.join(dir, `${baseName} (${suffix})${ext}`);
    counter++;
  } while (fs.existsSync(newPath));

  return newPath;
}

/**
 * Convert a DOCX to PDF safely using a temporary directory.
 */
async function convertDocxToPdf(inputFile: string, outputFile?: string) {
  return new Promise<string>((resolve, reject) => {
    const absInput = path.resolve(inputFile);
    const tempDir = makeTempDir(); // ← SAFE PLACE

    const basePDFName = path.basename(absInput).replace(/\.docx$/i, ".pdf");

    const finalOutput = outputFile
      ? path.resolve(outputFile)
      : path.join(path.dirname(absInput), basePDFName);

    const safeFinalOutput = getUniqueFilePath(finalOutput);

    console.log(`Resolved output path: ${safeFinalOutput}`);

    const cmd = `/opt/homebrew/bin/soffice --headless --convert-to pdf --outdir "${tempDir}" "${absInput}"`;

    exec(cmd, (err, stdout, stderr) => {
      if (err) return reject(err);

      const generated = path.join(tempDir, basePDFName);

      if (!fs.existsSync(generated)) {
        return reject(new Error("LibreOffice did not generate a PDF."));
      }

      fs.renameSync(generated, safeFinalOutput);
      fs.rmSync(tempDir, { recursive: true, force: true });

      resolve(safeFinalOutput);
    });
  });
}

// --- CLI ---
const inputPath = process.argv[2];
const outputPath = process.argv[3];
const savePdfPreference = process.argv
  .find((arg) => arg.startsWith("--save-pdf="))
  ?.split("=")[1];
const savePdf = savePdfPreference === "false" ? false : true;

const copyBase64Preference = process.argv
  .find((arg) => arg.startsWith("--copy-base64="))
  ?.split("=")[1];
const copyBase64 = copyBase64Preference === "true" ? true : false;

if (!inputPath) {
  console.error("Usage: bun run docx-to-pdf.ts <input.docx> [output.pdf]");
  process.exit(1);
}
console.log({ inputPath, outputPath });

convertDocxToPdf(inputPath, outputPath)
  .then(async (pdfPath) => {
    console.log("PDF created at:", pdfPath);

    if (copyBase64) {
      const pdfBuffer = fs.readFileSync(pdfPath);
      const base64 = pdfBuffer.toString("base64");
      await new Promise<void>((resolve, reject) => {
        const pbcopy = exec("pbcopy", (err) => {
          if (err) reject(err);
          else resolve();
        });
        pbcopy.stdin?.write(base64);
        pbcopy.stdin?.end();
      });
      console.log("Base64 copied to clipboard");
    }

    if (!savePdf) {
      fs.rmSync(pdfPath, { force: true });
      console.log("PDF file removed (savePdf=false)");
      return;
    } else {
      const directory = path.dirname(pdfPath);
      const fileName = path.basename(pdfPath);
      const report = {
        type: "reload-path",
        path: directory,
        fileToSelect: fileName,
      };
      console.log("[koda]: ", JSON.stringify(report));
    }
  })
  .catch((err) => {
    console.error("Conversion failed:", err);
    throw err;
  });
