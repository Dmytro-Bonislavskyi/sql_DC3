const fs = require('fs')

function jsonToMarkdownTable(data) {
  if (!data || data.length === 0) return ""

  const headers = Object.keys(data[0])
  let table = `| ${headers.join(" | ")} |\n`
  table += `| ${headers.map(() => "---").join(" | ")} |\n`

  for (const row of data) {
    table += `| ${headers.map(h => row[h]).join(" | ")} |\n`
  }

  return table
}

const file_read_result = fs.readFileSync('test-results.json', 'utf8')
const results = JSON.parse(file_read_result)

// Format PR comment
let body = `### 🧪 SQL Queries Run Results (up to 3 rows)\n\n`
body += `<details> <summary>Click to expand/collapse assignment queries execution results</summary>`

for (const result of results) {
    if (result.result && result.result.length > 0) {
      body += `✅ Query ${result.number}: \n\n *${result.query}*, \n\n **Results**:  \n`
      const table = jsonToMarkdownTable(result.result)
      body +=  `${table} \n`
      body += `\n`
      body += `-------------------------------------------------------- \n` 
  }
}

body += `</details>`

console.log(body)