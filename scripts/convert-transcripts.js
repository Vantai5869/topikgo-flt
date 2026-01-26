const fs = require('fs');
const path = require('path');

// Read the TypeScript data file
const inputPath = '/Users/phamvantai/Documents/PRIVATE/TopikgoMB/topikgo/data/audio-transcript-data.ts';
const outputPath = path.join(__dirname, '../assets/data/audio-transcripts.json');

console.log('Reading transcript data from:', inputPath);

// Read the file content
const content = fs.readFileSync(inputPath, 'utf8');

// Extract the JSON array from the TypeScript file
// The file exports: export const transAudio= [...]
const match = content.match(/export const transAudio\s*=\s*(\[[\s\S]*\]);?$/m);

if (!match) {
  console.error('Could not find transAudio export in the file');
  process.exit(1);
}

// Parse the JSON
let jsonData;
try {
  jsonData = JSON.parse(match[1]);
} catch (error) {
  console.error('Error parsing JSON:', error.message);
  process.exit(1);
}

console.log(`Found ${jsonData.length} transcript entries`);

// Create a simplified version for Flutter
const flutterData = jsonData.map(item => ({
  id: item.id,
  audioUrl: item.audio_url,
  text: item.text,
  utterances: item.utterances?.map(utterance => ({
    speaker: utterance.speaker,
    text: utterance.text,
    confidence: utterance.confidence,
    start: utterance.start,
    end: utterance.end
  })) || [],
  confidence: item.confidence,
  audioDuration: item.audio_duration
}));

// Write to output file
fs.writeFileSync(outputPath, JSON.stringify(flutterData, null, 2), 'utf8');

console.log(`Successfully wrote ${flutterData.length} transcript entries to:`, outputPath);
console.log('File size:', (fs.statSync(outputPath).size / 1024 / 1024).toFixed(2), 'MB');
