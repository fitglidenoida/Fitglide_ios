const fs = require('fs');
const axios = require('axios');

// Configuration
const STRAPI_URL = 'https://admin.fitglide.in/api';
const API_TOKEN = 'ec25245aa7df9aa5b57818bd6fd194565b42131e3864ff8b74539684923db906a11c58d82b087dad65dd1330ae3120aa8be7106c50e7cf3a7bd2da9fc7c6d63daec229233f81bd0d9cd4a36c0b8e965afa1cfde311baf255610648a9bcd8f0ba9db2c4b3131fe75a5bfa0773ef550a3599a9424129209ba4a981e85a79702fb1'; // Replace with your actual token

// Read the JSON file
const messagesData = JSON.parse(fs.readFileSync('./desi_messages_sample.json', 'utf8'));

async function importMessages() {
    console.log('🚀 Starting bulk import of desi messages...');
    console.log(`📊 Total messages to import: ${messagesData.desi_messages.length}`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (let i = 0; i < messagesData.desi_messages.length; i++) {
        const message = messagesData.desi_messages[i];
        
        try {
            console.log(`📝 Importing message ${i + 1}/${messagesData.desi_messages.length}: ${message.title}`);
            
            const response = await axios.post(`${STRAPI_URL}/desi-messages`, {
                data: {
                    title: message.title,
                    yesterday_line: message.yesterday_line,
                    today_line: message.today_line,
                    message_text: message.message_text, // Added this field
                    message_type: message.message_type,
                    priority: message.priority,
                    is_active: message.is_active,
                    language_style: message.language_style,
                    min_level: message.min_level,
                    max_level: message.max_level
                }
            }, {
                headers: {
                    'Authorization': `Bearer ${API_TOKEN}`,
                    'Content-Type': 'application/json'
                }
            });
            
            console.log(`✅ Success: ${message.title}`);
            successCount++;
            
            // Add a small delay to avoid overwhelming the server
            await new Promise(resolve => setTimeout(resolve, 100));
            
        } catch (error) {
            console.error(`❌ Error importing "${message.title}":`, error.response?.data || error.message);
            errorCount++;
        }
    }
    
    console.log('\n📈 Import Summary:');
    console.log(`✅ Successfully imported: ${successCount} messages`);
    console.log(`❌ Failed to import: ${errorCount} messages`);
    console.log(`📊 Total processed: ${successCount + errorCount} messages`);
}

// Alternative: Bulk import using Strapi's bulk endpoint (if available)
async function bulkImportMessages() {
    console.log('🚀 Starting bulk import using bulk endpoint...');
    
    try {
        const response = await axios.post(`${STRAPI_URL}/desi-messages/bulk`, {
            data: messagesData.desi_messages.map(message => ({
                title: message.title,
                yesterday_line: message.yesterday_line,
                today_line: message.today_line,
                message_text: message.message_text, // Added this field
                message_type: message.message_type,
                priority: message.priority,
                is_active: message.is_active,
                language_style: message.language_style,
                min_level: message.min_level,
                max_level: message.max_level
            }))
        }, {
            headers: {
                'Authorization': `Bearer ${API_TOKEN}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log('✅ Bulk import successful!');
        console.log(`📊 Imported ${messagesData.desi_messages.length} messages`);
        
    } catch (error) {
        console.error('❌ Bulk import failed:', error.response?.data || error.message);
        console.log('🔄 Falling back to individual imports...');
        await importMessages();
    }
}

// Check if axios is available, if not provide installation instructions
async function checkDependencies() {
    try {
        require('axios');
        console.log('✅ Axios is available');
        return true;
    } catch (error) {
        console.log('❌ Axios not found. Please install it first:');
        console.log('npm install axios');
        return false;
    }
}

// Main execution
async function main() {
    console.log('🔧 Desi Messages Bulk Import Script');
    console.log('=====================================\n');
    
    if (!await checkDependencies()) {
        return;
    }
    
    if (!API_TOKEN || API_TOKEN === 'YOUR_STRAPI_API_TOKEN') {
        console.log('❌ Please update the API_TOKEN in the script with your actual Strapi API token');
        console.log('💡 You can find your token in Strapi Admin → Settings → API Tokens');
        return;
    }
    
    // Try bulk import first, fall back to individual imports
    await bulkImportMessages();
}

// Run the script
main().catch(console.error);
