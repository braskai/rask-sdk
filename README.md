# Rask SDK
Our SDK makes it easy for developers to integrate Rask AI services into their applications quickly and seamlessly by providing them with an easy-to-use Python client. 
## 1. Interface
Below you can find a list of all available methods with their input and output data formats.
```python

class RaskSDKClient:
    """."""
    
    async def authenticate(self) -> None:
        """Fetch new token for the instantiated client."""
    
    async def get_credits(self) -> schemas.CreditsGet:
        """Get credits of the current user."""
    
    async def create_media_file(
        self, file: BinaryIO, kind: Optional[enums.MediaKind] = None, timeout: int = 1800
    ) -> schemas.MediaGet:
        """Create media by binary file provided."""
        
    async def create_media_link(self, data: schemas.MediaCreateLink) -> schemas.MediaGet:
        """Create media by link provided."""

    async def get_media(self, media_id: uuid.UUID) -> schemas.MediaGet:
        """Get media by id."""
        
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
        self, project_id: uuid.UUID
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

## 2. Authentication
Our SDK contains refresh token logic inside the `RaskSDKClient`, so you do not really have to implement this logic on your side. 
You can do it if you want using `authenticate` method, but in general you can just initialize the client and use it as is.

## 3. Quick start
In this example, let's look at our basic flow, which includes the following steps:
- Upload a media
- Create a glossary
- Create and dub a project with both items
- Update project transcription
- Redub the project
- Run lipsync for the project
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
        await asyncio.sleep(3)
    
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
        await asyncio.sleep(3)
    
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
        await asyncio.sleep(3)


if __name__ == "__main__":
    asyncio.run(main())
```