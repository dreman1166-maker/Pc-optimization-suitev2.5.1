# PowerShell script to automate GitHub Pages upload for legal files
# Fill in your GitHub username and personal access token below

$repoName = "discord-bot-legal"
$githubUser = "YOUR_GITHUB_USERNAME"
$githubToken = "YOUR_GITHUB_TOKEN"
$apiUrl = "https://api.github.com/user/repos"
$localPath = "C:/Users/drema/AutoKey"
$remoteUrl = "https://$githubToken@github.com/$githubUser/$repoName.git"

# Create repo on GitHub
$body = @{name=$repoName;auto_init=$true;private=$false} | ConvertTo-Json
Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization = "token $githubToken"} -Method Post -Body $body

# Initialize git and push files
cd $localPath
git init
git remote add origin $remoteUrl
git pull origin main
git add terms.html privacy.html
git commit -m "Add legal files"
git push origin main

# Enable GitHub Pages (root)
$pagesApi = "https://api.github.com/repos/$githubUser/$repoName/pages"
$pagesBody = @{source=@{branch="main";path="/"}} | ConvertTo-Json
Invoke-RestMethod -Uri $pagesApi -Headers @{Authorization = "token $githubToken"} -Method Post -Body $pagesBody

Write-Host "Done! Your files will be live at: https://$githubUser.github.io/$repoName/terms.html"
