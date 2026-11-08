# =============================================================
# 00_check_git.R
# Step 0b: is Git installed, and is it linked to GitHub?
# Run line by line in RStudio and read the output.
# =============================================================

# 1. Is Git installed on this Mac?
#    Expected: something like "git version 2.39.5".
#    If you get an error, or macOS pops up a window offering to install
#    "command line developer tools", click Install, wait, then re-run this line.
system("git --version")

# 2. The full situation report from usethis.
#    Read three parts of the output:
#    - "Git global (user)": are user.name and user.email filled in?
#    - "GitHub user": does it show your GitHub username?
#    - "Personal access token": does it say a token was found?
#    Copy the whole output and paste it to Claude; I will tell you what to fix.
usethis::git_sitrep()
