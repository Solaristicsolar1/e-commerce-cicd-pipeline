#!/bin/bash

echo "🚀 Creating E-Commerce CI/CD Pipeline..."

# Create source zip for initial pipeline run
echo "📦 Creating source package..."
zip -r source.zip . -x "*.git*" "*.zip" "complete-setup.sh" "create-pipeline.sh"

# Upload source to S3
echo "⬆️ Uploading source to S3..."
aws s3 cp source.zip s3://codepipeline-us-east-1-artifacts-192018386876/source.zip --region us-east-1

# Create the pipeline
echo "🔧 Creating CodePipeline..."
aws codepipeline create-pipeline --cli-input-json file://simple-pipeline.json --region us-east-1

echo ""
echo "✅ Pipeline Created Successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Go to AWS Console → CodePipeline → ecommerce-pipeline"
echo "2. Edit the Source stage to connect to your GitHub repository"
echo "3. Replace S3 source with GitHub source:"
echo "   - Provider: GitHub"
echo "   - Repository: Solaristicsolar1/e-commerce-cicd-pipeline"
echo "   - Branch: main"
echo "4. Save and run the pipeline"
echo ""
echo "🌐 Your application URL: http://ecommerce-alb-671447400.us-east-1.elb.amazonaws.com"
echo ""
echo "🎉 CI/CD Pipeline Setup Complete!"
