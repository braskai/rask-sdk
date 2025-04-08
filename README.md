# Rask SDK
This SDK provides an official Python client for the Rask API. For full API reference and authentication setup, see [Rask API Docs](https://docs.api.rask.ai/introduction).
## 1. Installation
Rask SDK can be installed by the direct link to the repository using any Python package manager. 

Below you can find an example of how to do this using `pip`:
```shell
pip install git+ssh://git@github.com/braskai/rask-sdk.git@main
```
Or using `poetry` and `pyproject.toml`:
```shell
[tool.poetry.dependencies]
rask-sdk = { branch = "main", git = "git@github.com:braskai/rask-sdk.git" }
```

## 2. Interface
Below you can find a list of all available methods with their input and output data formats.
### Authenticate and check minutes balance
```python

class RaskSDKClient:
    """."""
    
    async def authenticate(self) -> None:
        """Fetch new token for the instantiated client."""
    
    async def get_credits(self) -> schemas.CreditsGet:
        """Get credits of the current user."""
```
### Manage Media
```python

class RaskSDKClient:
    """."""
    
    async def create_media_file(
        self, file: BinaryIO, kind: Optional[enums.MediaKind] = None, timeout: int = 1800
    ) -> schemas.MediaGet:
        """Create media by binary file provided."""
        
    async def create_media_link(self, data: schemas.MediaCreateLink) -> schemas.MediaGet:
        """Create media by link provided."""

    async def get_media(self, media_id: uuid.UUID) -> schemas.MediaGet:
        """Get media by id."""
```
### Manage Projects
```python

class RaskSDKClient:
    """."""
        
    async def create_project(self, data: schemas.ProjectCreate) -> schemas.ProjectGet:
        """Create project."""
        
    async def get_project(self, project_id: uuid.UUID) -> schemas.ProjectGet:
        """Get project by id."""
        
    async def get_projects(
        self, offset: int = 0, limit: int = 10, name: Optional[str] = None
    ) -> schemas.ProjectsGet:
        """Get project list."""
    
    async def generate_project(self, project_id: uuid.UUID) -> schemas.ProjectGet:
        """Generate project."""

    async def patch_project(
        self, project_id: uuid.UUID, data: schemas.ProjectPatch
    ) -> schemas.ProjectGet:
        """Patch project."""

    async def get_project_voices(self, project_id: uuid.UUID) -> List[schemas.Voice]:
        """Get project voices."""
```
### Generate Lip-Sync
```python
    async def run_check_face_task(
        self, project_id: uuid.UUID
    ) -> schemas.CheckFaceTaskResponse:
        """Run check face task for project id provided."""

    async def run_lipsync_task(
        self,
        project_id: uuid.UUID,
        data: schemas.LipsyncTaskData,
    ) -> schemas.LipsyncTaskResponse:
        """Run lipsync task for project id provided."""

    async def get_lipsync_info(self, project_id: uuid.UUID) -> schemas.LipsyncInfo:
        """Get lipsync info."""
```
### Manage Transcription
```python
    async def create_transcription(
        self, data: schemas.TranscriptionCreate
    ) -> schemas.TranscriptionId:
        """Create transcription."""

    async def create_transcription_srt(
        self,
        src: Optional[BinaryIO] = None,
        dst: Optional[BinaryIO] = None,
        src_lang: Optional[str] = None,
        dst_lang: Optional[str] = None,
        timeout: int = 1800,
    ) -> schemas.TranscriptionId:
        """Create transcription via .srt uploading."""

    async def get_project_transcription(
        self,
        project_id: uuid.UUID,
        segment_ids: Optional[List[uuid.UUID]] = None,
    ) -> schemas.TranscriptionGet:
        """Get transcription associated with the project."""

    async def add_project_transcription_segments(
        self, project_id: uuid.UUID, data: schemas.TranscriptionSegmentsCreate
    ) -> schemas.TranscriptionGet:
        """Create segments in the transcription associated with the project."""

    async def patch_project_transcription_segments(
        self, project_id: uuid.UUID, data: schemas.TranscriptionSegmentsPatch
    ) -> schemas.TranscriptionGet:
        """Patch segments in the transcription associated with the project."""

    async def delete_project_transcription_segment(
        self, project_id: uuid.UUID, segment_id: uuid.UUID
    ) -> schemas.SegmentId:
        """Delete the segment in the transcription associated with the project."""
```
### Manage Glossary
```python
    async def create_glossary(self, data: schemas.GlossaryCreate) -> schemas.GlossaryGet:
        """Create new glossary."""

    async def get_glossary(self, glossary_id: uuid.UUID) -> schemas.GlossaryGet:
        """Get glossary by id."""

    async def update_glossary(
        self, glossary_id: uuid.UUID, data: schemas.GlossaryUpdate
    ) -> schemas.GlossaryGet:
        """Update existing glossary."""

    async def delete_glossary(self, glossary_id: uuid.UUID) -> schemas.GlossaryIdGet:
        """Delete glossary by id."""
```

## 3. Authentication
Our SDK contains refresh token logic inside the `RaskSDKClient`, so you do not really have to implement this logic on your side. 
You can do it if you want using `authenticate` method, but in general you can just initialize the client and use it as is.

To obtain your API credentials from your Rask account settings, follow instructions [here](https://help.rask.ai/hc/introducing-rask-api-rask-help-center).

## 4. Quick start
In this example, let's look at our basic flow, which includes the following steps:
- Upload a media
- Create a glossary
- Create and dub a project with both items
- Update project transcription
- Redub the project
- Run lipsync for the project

To learn more about workflows you can set up, check out the pages under **Workflow** section in our [API docs](https://docs.api.rask.ai/workflow/translation).
```python
import asyncio

from rask_sdk import enums
from rask_sdk import schemas
from rask_sdk import clients


async def main():
    # Initialize client
    client = clients.RaskSDKClient(
        client_id="MY_CLIENT_ID",
        client_secret="MY_CLIENT_SECRET",
    )
    
    # Upload a media
    with open("video.mp4", "rb") as video:
        media = await client.create_media_file(kind=enums.MediaKind.VIDEO, file=video)
    
    # Create a glossary
    glossary = await client.create_glossary(
        data=schemas.GlossaryCreate(
            name="SDK Glossary",
            src_lang="pt",
            dst_lang="en",
            entries={"Olá": "Hello"}
        )
    )
    
    # Create a project with both items provided
    project = await client.create_project(
        data=schemas.ProjectCreate(
            video_id=media.id,
            name="SDK Project",
            dst_lang="en-us",
            glossary_id=glossary.id
        )
    )
    
    # Fetch project status waiting for dubbing to be completed
    while project.status is not enums.ProjectStatus.MERGING_DONE:
        project = await client.get_project(project_id=project.id)
        await asyncio.sleep(10)
    
    # Get project transcription
    transcription = await client.get_project_transcription(project_id=project.id)
    
    # Update certain project transcription segments 
    segments_ = await client.patch_project_transcription_segments(
        project_id=project.id,
        data=schemas.TranscriptionSegmentsPatch(
            segments=[
                schemas.SegmentPatch(id=..., speaker="SPEAKER_01")
            ]
        )
    )
    
    # Redub the project to apply the changes
    project = await client.generate_project(project_id=project.id)
    
    # Fetch project status waiting for redubbing to be completed
    while project.status is not enums.ProjectStatus.MERGING_DONE:
        project = await client.get_project(project_id=project.id)
        await asyncio.sleep(10)
    
    # Get lipsync info
    lipsync_info = await client.get_lipsync_info(project_id=project.id)
    
    # If the face has not been detected automatically, do it manually
    if lipsync_info.check_face_task_status is not enums.LipsyncStatus.DONE:
        await client.run_check_face_task(project_id=project.id)

    # Run lipsync task
    lipsync_response_ = await client.run_lipsync_task(project_id=project.id, data=schemas.LipsyncTaskData())
    
    # Fetch lipsync info waiting for lipsync to be completed
    while lipsync_info.lipsync_task_status is not enums.LipsyncStatus.DONE:
        lipsync_info = await client.get_lipsync_info(project_id=project.id)
        await asyncio.sleep(10)


if __name__ == "__main__":
    asyncio.run(main())
```
> **Tip:** some operations (generating voiceover, lipsync or re-dubbing the project) take time to complete - please make sure to adjust your polling intervals accordingly. 

## 5. Supported languages

We support over **130 target languages and dialects**.  
When working with the SDK, make sure to specify the langauge - whether  **source** or **destination** or both - using the appropriate **language codes**.

You can find the full list of supported language codes in our [API documentation](https://docs.api.rask.ai/languages) - be sure to double-check the correct format for your specific context.

## 6. About SDK Schemas
Many SDK methods accept or return structured data using [Pydantic](https://docs.pydantic.dev/latest/) models defined in `rask_sdk.schemas`.

These models provide:
- Structured request bodies (e.g. `ProjectCreate`, `TranscriptionCreate`)
- Typed, autocompletable responses (e.g. `TranscriptionGet`, `ProjectGet`)
- Built-in validation and serialization
#### Usage Example

```python
from rask_sdk import schemas

# Access schema types
project = schemas.ProjectCreate(...)

# Convert to JSON-compatible dict (Pydantic v2+)
json_data = project.model_dump()
```
## 7. Supported Features Matrix


| **SDK Method** | **API Docs**                                             |
|----------------|----------------------------------------------------------|
| `authenticate()` | [Authentication](https://docs.api.rask.ai/authentication) |
| `get_credits()` | [Get credits](https://docs.api.rask.ai/api-reference/user/get_credits) |
| `create_media_file(...)` | [Upload media by file](https://docs.api.rask.ai/api-reference/media/upload_media_file) |
| `create_media_link(...)` | [Upload media by link](https://docs.api.rask.ai/api-reference/media/upload_media_link) |
| `get_media(...)` | [Get media](https://docs.api.rask.ai/api-reference/media/get_media)|
| `create_project(...)` | [Create project](https://docs.api.rask.ai/api-reference/project/create_project) |
| `get_project(...)` | [Get project](https://docs.api.rask.ai/api-reference/project/get_project) |
| `get_projects(...)` | [Get project list](https://docs.api.rask.ai/api-reference/project/get_project_list) |
| `generate_project(...)` | [Generate project](https://docs.api.rask.ai/api-reference/project/generate_project) |
| `patch_project(...)` | [Patch project](https://docs.api.rask.ai/api-reference/project/patch_project) |
| `get_project_voices(...)` | [Get project voices](https://docs.api.rask.ai/api-reference/project/get_voices) |
| `run_check_face_task(...)` | [Run check face](https://docs.api.rask.ai/api-reference/lipsync/run_check_face) |
| `run_lipsync_task(...)` | [Run Lip-sync](https://docs.api.rask.ai/api-reference/lipsync/run_lipsync) |
| `get_lipsync_info(...)` | [Get Lip-sync info](https://docs.api.rask.ai/api-reference/lipsync/get_lipsync) |
| `create_transcription(...)` | [Create transcription](https://docs.api.rask.ai/api-reference/project/create_transcription) |
| `create_transcription_srt(...)` | [Create transcription srt](https://docs.api.rask.ai/api-reference/project/create_transcription_srt) |
| `get_project_transcription(...)` | [Get transcription](https://docs.api.rask.ai/api-reference/project/get_transcription) |
| `add_project_transcription_segments(...)` | [Add segments](https://docs.api.rask.ai/api-reference/project/add_segments) |
| `patch_project_transcription_segments(...)` | [Patch segments](https://docs.api.rask.ai/api-reference/project/patch_segments) |
| `delete_project_transcription_segment(...)` | [Delete segment](https://docs.api.rask.ai/api-reference/project/delete_segment) |
| `create_glossary(...)` | [Create glossary](https://docs.api.rask.ai/api-reference/glossary/create_glossary) |
| `get_glossary(...)` | [Get glossary](https://docs.api.rask.ai/api-reference/glossary/get_glossary) |
| `update_glossary(...)` | [Update glossary](https://docs.api.rask.ai/api-reference/glossary/update_glossary) |
| `delete_glossary(...)` | [Delete glossary](https://docs.api.rask.ai/api-reference/glossary/delete_glossary) |