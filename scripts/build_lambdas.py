import os
import zipfile

SERVICES_DIR = "services"
LAMBDAS = ["Ingestion", "TextModeration", "ImageModeration", "VideoModeration", "DecisionEngine", "UploadApi"]

for lambda_name in LAMBDAS:
    lambda_dir = os.path.join(SERVICES_DIR, lambda_name)
    zip_path = os.path.join(lambda_dir, f"{lambda_name}.zip")

    # Remove old zip
    if os.path.exists(zip_path):
        os.remove(zip_path)

    # Optional: install requirements if exists
    requirements = os.path.join(lambda_dir, "requirements.txt")
    if os.path.exists(requirements):
        print(f"Installing dependencies for {lambda_name}")
        os.system(f"pip install -r {requirements} -t {lambda_dir}")

    # Build zip
    print(f"Building Lambda: {lambda_name}")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(lambda_dir):
            for file in files:
                if file.endswith(".zip"):
                    continue
                filepath = os.path.join(root, file)
                arcname = os.path.relpath(filepath, lambda_dir)
                zipf.write(filepath, arcname)

    print(f"Created zip: {zip_path}")

print("All Lambdas built successfully!")
