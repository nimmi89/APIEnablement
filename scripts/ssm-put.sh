echo "Fetching variables"
echo "GIT_SHA : ${GIT_SHA}"
echo "VERSION : ${VERSION}"

echo "Storing app Info"
aws ssm put-parameter \
                --name GIT_SHA \
                --value ${GIT_SHA} \
                --type SecureString \
                --overwrite \
                --region ap-southeast-2


aws ssm put-parameter \
                --name VERSION \
                --value ${VERSION} \
                --type SecureString \
                --overwrite \
                --region ap-southeast-2
