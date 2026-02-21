const fs = require('fs');
const path = require('path');

const files = [
    '/opt/homebrew/lib/node_modules/openclaw/dist/pi-embedded-CNutRYOy.js',
    '/opt/homebrew/lib/node_modules/openclaw/dist/pi-embedded-n26FO9Pa.js',
    '/opt/homebrew/lib/node_modules/openclaw/dist/reply-B1AnbNl6.js',
    '/opt/homebrew/lib/node_modules/openclaw/dist/subagent-registry-kdTa9uwX.js'
];

const targetFunction = 'async function buildModelsProviderData(cfg) {';
const replacement = `async function buildModelsProviderData(cfg) { return { byProvider: new Map([["openrouter", new Set(["google/gemini-2.5-flash-lite-preview-09-2025"])]]), providers: ["openrouter"] };`;

files.forEach(file => {
    if (fs.existsSync(file)) {
        console.log(`Patching ${file}...`);
        let content = fs.readFileSync(file, 'utf8');
        // Replace the function start with the version that returns immediately.
        // The rest of the original function body will be unreachable code, which is fine for JS.
        const newContent = content.replace(targetFunction, replacement);

        // Also patch buildProviderKeyboard just in case to force it to respect what it gets
        // ACTUALLY, if data is filtered, keyboard is fine. 
        // But let's verify if replacement happened.
        if (newContent !== content) {
            fs.writeFileSync(file, newContent, 'utf8');
            console.log(`Successfully patched ${file}`);
        } else {
            console.log(`Target function not found in ${file}`);
        }
    } else {
        console.log(`File not found: ${file}`);
    }
});
