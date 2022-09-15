# Gitlab操作

```bash
Command line instructions
You can also upload existing files from your computer using the instructions below.

Git global setup
git config --global user.name "Administrator"
git config --global user.email "admin@example.com"
Create a new repository
git clone http://43.142.94.192/gitlab-instance-14b6c2b7/Monitoring.git
cd Monitoring
git switch -c main
touch README.md
git add README.md
git commit -m "add README"
git push -u origin main
Push an existing folder
cd existing_folder
git init --initial-branch=main
git remote add origin http://43.142.94.192/gitlab-instance-14b6c2b7/Monitoring.git
git add .
git commit -m "Initial commit"
git push -u origin main
Push an existing Git repository
cd existing_repo
git remote rename origin old-origin
git remote add origin http://43.142.94.192/gitlab-instance-14b6c2b7/Monitoring.git
git push -u origin --all
git push -u origin --tags
```

