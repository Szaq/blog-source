hugo
cd public
git add *
git commit -m "$1"
git push
cd ..
git add public
git add content
git commit -m "$1"
git push
