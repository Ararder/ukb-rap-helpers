import dxpy
import sys

# 1. Setup
if len(sys.argv) < 2:
    print("Usage: python3 get_field.py <field_id>")
    sys.exit(1)

field_id = sys.argv[1]
project_id = dxpy.PROJECT_CONTEXT_ID

# 2. Find the dataset - More robust search
try:
    # We search for any record object with a name containing '.dataset'
    search_results = list(dxpy.find_data_objects(classname="record", name="*.dataset", name_mode="glob", project=project_id))
    
    if not search_results:
        # Try finding by type if name fails
        search_results = list(dxpy.find_data_objects(classname="record", type="Dataset", project=project_id))

    if not search_results:
        print("Error: Could not find any .dataset file in this project.")
        sys.exit(1)

    dataset_id = search_results[0]['id']
    print(f"Using Dataset: {dataset_id}")

except Exception as e:
    print(f"Search failed: {e}")
    sys.exit(1)

# 3. Define output and fields
output_name = f"field_{field_id}_extract.csv"
full_field_name = f"participant.p{field_id}"

# 4. Submit the background job
# Note: 'app-extract_dataset' is the underlying app for 'dx extract_dataset'
try:
    print(f"Submitting background job for {full_field_name}...")
    
    # We use the dataset's project to ensure it can see the file
    job = dxpy.DXApplet(alias="app-extract_dataset").run(
        input={
            "dataset_or_cohort": {"$dnanexus_link": dataset_id},
            "fields": ["participant.eid", full_field_name],
            "output": output_name
        },
        instance_type="mem1_ssd1_v2_x4"
    )
    
    print(f"SUCCESS! Job ID: {job.get_id()}")
    print(f"Track with: dx monitor {job.get_id()}")
    print(f"When finished, run: dx download {output_name}")

except Exception as e:
    print(f"Failed to submit job: {e}")
