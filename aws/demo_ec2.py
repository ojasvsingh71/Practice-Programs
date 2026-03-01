import re
import logging
import boto3
import pandas as pd
import streamlit as st
from botocore.exceptions import ClientError

# -----------------------------
# Basic Configuration
# -----------------------------
st.set_page_config(
    page_title="EC2 Streamlit S3 Manager",
    layout="wide"
)

logging.basicConfig(level=logging.INFO)

# -----------------------------
# Utility Functions
# -----------------------------

def get_s3_client(region: str):
    return boto3.client("s3", region_name=region)


def is_valid_bucket_name(name: str) -> bool:
    if len(name) < 3 or len(name) > 63:
        return False
    if not re.match(r"^[a-z0-9][a-z0-9.-]+[a-z0-9]$", name):
        return False
    return True


def list_buckets(s3):
    try:
        response = s3.list_buckets()
        return sorted([b["Name"] for b in response.get("Buckets", [])])
    except ClientError as e:
        logging.error(e)
        st.error("Unable to list buckets.")
        return []


def create_bucket(s3, bucket_name: str, region: str):
    try:
        if region == "us-east-1":
            s3.create_bucket(Bucket=bucket_name)
        else:
            s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={"LocationConstraint": region},
            )
        return True, "Bucket created successfully."
    except ClientError as e:
        return False, str(e)


def delete_bucket(s3, bucket_name: str):
    try:
        objects = s3.list_objects_v2(Bucket=bucket_name)
        if objects.get("KeyCount", 0) > 0:
            return False, "Bucket is not empty. Delete objects first."
        s3.delete_bucket(Bucket=bucket_name)
        return True, "Bucket deleted successfully."
    except ClientError as e:
        return False, str(e)


def upload_file_to_s3(s3, bucket: str, file):
    try:
        s3.upload_fileobj(file, bucket, file.name)
        return True, f"File uploaded to s3://{bucket}/{file.name}"
    except ClientError as e:
        return False, str(e)


# -----------------------------
# Sidebar - Region Selection
# -----------------------------
st.sidebar.title("⚙️ Configuration")

region = st.sidebar.text_input(
    "Enter AWS Region",
    value="ap-south-1"
)

st.sidebar.info("Example: ap-south-1 (Mumbai), us-east-1, eu-west-1")

# Initialize S3 Client
s3_client = get_s3_client(region)

# -----------------------------
# Main UI
# -----------------------------
st.title("☁️ AWS S3 Manager ")

tabs = st.tabs([
    "📋 List Buckets",
    "➕ Create Bucket",
    "❌ Delete Bucket",
    "⬆️ Upload File"
])

# -----------------------------
# TAB 1 - List Buckets
# -----------------------------
with tabs[0]:
    st.subheader("Available S3 Buckets")

    if st.button("Refresh Buckets", key="refresh_btn"):
        st.session_state["buckets"] = list_buckets(s3_client)

    buckets = st.session_state.get("buckets", list_buckets(s3_client))

    if buckets:
        st.success(f"Total Buckets: {len(buckets)}")
        st.table(pd.DataFrame(buckets, columns=["Bucket Name"]))
    else:
        st.warning("No buckets found.")


# -----------------------------
# TAB 2 - Create Bucket
# -----------------------------
with tabs[1]:
    st.subheader("Create New Bucket")

    bucket_name = st.text_input(
        "Bucket Name",
        key="create_bucket_input"
    )

    if st.button("Create Bucket", key="create_bucket_btn"):
        if not is_valid_bucket_name(bucket_name):
            st.error("Invalid bucket name format.")
        else:
            success, message = create_bucket(s3_client, bucket_name, region)
            if success:
                st.success(message)
            else:
                st.error(message)


# -----------------------------
# TAB 3 - Delete Bucket
# -----------------------------
with tabs[2]:
    st.subheader("Delete Existing Bucket")

    buckets = list_buckets(s3_client)

    bucket_to_delete = st.selectbox(
        "Select Bucket",
        options=[""] + buckets,
        key="delete_bucket_select"
    )

    if st.button("Delete Bucket", key="delete_bucket_btn"):
        if not bucket_to_delete:
            st.error("Please select a bucket.")
        else:
            success, message = delete_bucket(s3_client, bucket_to_delete)
            if success:
                st.success(message)
            else:
                st.error(message)


# -----------------------------
# TAB 4 - Upload File
# -----------------------------
with tabs[3]:
    st.subheader("Upload File to S3")

    buckets = list_buckets(s3_client)

    upload_bucket = st.selectbox(
        "Select Bucket",
        options=[""] + buckets,
        key="upload_bucket_select"
    )

    uploaded_file = st.file_uploader(
        "Browse File",
        key="file_uploader"
    )

    if st.button("Upload File", key="upload_btn"):
        if not upload_bucket:
            st.error("Please select a bucket.")
        elif not uploaded_file:
            st.error("Please upload a file.")
        else:
            success, message = upload_file_to_s3(
                s3_client,
                upload_bucket,
                uploaded_file
            )
            if success:
                st.success(message)
            else:
                st.error(message)