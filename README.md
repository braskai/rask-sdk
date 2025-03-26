# Rask SDK
Rask developer kit to simplify work with API
## Draft
```python
import asyncio

from rask_sdk import enums
from rask_sdk import schemas
from rask_sdk import clients


async def main():
    client = clients.RaskSDKClient(
        client_id="MY_CLIENT_ID",
        client_secret="MY_CLIENT_SECRET",
    )

    with open("video.mp4", "rb") as video:
        media = await client.create_media_file(kind=enums.MediaKind.VIDEO, file=video)

    media = await client.get_media(media_id=media.id)

    glossary = await client.create_glossary(
        data=schemas.GlossaryCreate(
            name="SDK Glossary",
            src_lang="pt",
            dst_lang="en",
            entries={"Olá": "Hello"}
        )
    )
    glossary = await client.get_glossary(glossary_id=glossary.id)

    project = await client.create_project(
        data=schemas.ProjectCreate(
            video_id=media.id,
            name="SDK Project",
            dst_lang="en-us",
            glossary_id=glossary.id
        )
    )

    while project.status is not enums.ProjectStatus.MERGING_DONE:
        project = await client.get_project(project_id=project.id)
        await asyncio.sleep(3)

    transcription = await client.get_project_transcription(project_id=project.id)

    segment = await client.patch_project_transcription_segments(
        project_id=project.id,
        data=schemas.TranscriptionSegmentsPatch(
            segments=[
                schemas.SegmentPatch(id=..., speaker="SPEAKER_01")
            ]
        )
    )

    project = await client.generate_project(project_id=project.id)
    
    while project.status is not enums.ProjectStatus.MERGING_DONE:
        project = await client.get_project(project_id=project.id)
        await asyncio.sleep(3)

    lipsync_info = await client.get_lipsync_info(project_id=project.id)
    
    if lipsync_info.check_face_task_status is not enums.LipsyncStatus.DONE:
        await client.run_check_face_task(project_id=project.id)

    lipsync_response_ = await client.run_lipsync_task(project_id=project.id, data=schemas.LipsyncTaskData())

    while lipsync_info.lipsync_task_status is not enums.LipsyncStatus.DONE:
        lipsync_info = await client.get_lipsync_info(project_id=project.id)
        await asyncio.sleep(3)


if __name__ == "__main__":
    asyncio.run(main())

```