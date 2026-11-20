# LV Volume and Diastolic Filling from 3D Echo

MATLAB pipeline that measures left ventricle (LV) volume in every frame of a 3D echo DICOM, then computes EF and filling/ejection rates.

## How to run

1. Put the `.dcm` file in `Datasets/`.
2. In MATLAB, set the dataset name, then run the volume script from the `Scripts/` folder:
   ```matlab
   datasetName = '002A';      % file name without .dcm
   main_LeftVentricleVolume
   ```
   - Click the center of the LV on the short-axis image (once).
   - For each frame, click the two mitral hinge points on each of two long-axis views (4 clicks per frame).
   - Clicks are saved as you go, so you can stop and rerun without redoing them. Delete `Results/<dataset>/LeftVentricleVolumeResults.mat` to start over.
3. Run the filling analysis (same `datasetName` still in the workspace):
   ```matlab
   main_DiastolicFilling
   ```

If `datasetName` isn't set, it defaults to `002A`.

**Per-dataset settings** are in `setupWorkspace.m`:
- Volume rate comes from the DICOM Frame Time. If the header has no Frame Time, add the rate to `listedVolumesPerSecond`.
- To analyze only some volumes (e.g. one heartbeat), add them to `listedVolumeRanges`.
- To compare against scanner volumes, put a `MachineVolumes.csv` file (columns `Frame,VolumeMilliliters`) in `Results/<dataset>/`.

## Outputs (`Results/<dataset>/`)

| File | Contents |
|---|---|
| `LeftVentricleVolumes.csv` | Volume (mL) per frame |
| `LeftVentricleVolumeSummary.csv` | EDV, ESV, SV, EF, peak ejection and peak filling rates |
| `LeftVentricleVolume.png` | Volume and dV/dt curves |
| `VolumeOverlays/` | Segmentation overlay per frame (PNG) and as a video (MP4) |
| `LeftVentricleVolumeResults.mat` | Saved clicks, apex/axis, volumes, plane areas |
| `DiastolicFillingDiscrete.png`, `DiastolicFillingDiscreteMetrics.mat` | Filling-rate plots and metrics |

## Files

### `Scripts/`
| File | Description |
|---|---|
| `main_LeftVentricleVolume.m` | Main script: loads data, collects clicks, computes volume per frame, saves overlays, curves and summary |
| `main_DiastolicFilling.m` | Reads the volume CSV and computes EDV, ESV, SV, EF and peak filling rate |
| `setupWorkspace.m` | Sets paths, dataset, section settings, volume rate, frame range and output folder |
| `selectLeftVentricleCenter.m` | User clicks the LV center on a mid-depth slice |
| `findLongAxis.m` | Finds the apex and long-axis direction automatically from the cavity |
| `selectMitralHinges.m` | User clicks the mitral hinge points on two perpendicular long-axis views |
| `calculateLeftVentricleVolume.m` | Volume from stacked short-axis areas (frustum sum) from apex to the mitral hinge plane |
| `segmentShortAxisDiscs.m` | Segments the cavity on short-axis planes along the long axis and rejects outlier outlines |
| `segmentCavity.m` | Finds the blood/wall border on one short-axis image by casting rays from the center |
| `flattenBrightness.m` | Corrects the brightness gradient across a short-axis image |
| `extractObliqueSlice.m` | Samples a 2D slice at any orientation from the 3D volume |
| `extractObliqueSection.m` | Averages several oblique slices to make a thick section |
| `discGeometry.m` | Plane positions and directions along the apex–base axis |
| `perpendicularDirections.m` | Two unit vectors perpendicular to the long axis |
| `showVolumeOverlay.m` | Draws the long-axis views and short-axis outlines for one frame |
| `discrete_filling_rate.m` | EDV, ESV, SV, EF, dV/dt, and peak filling/ejection rates from a volume-time curve |
| `ginput_userdefinedcolour.m` | `ginput` with a custom crosshair color (from MATLAB Answers) |

### `ProvidedScripts/` (course-provided)
| File | Description |
|---|---|
| `resampleDicom.m` | Loads a 3D DICOM and resamples it to isotropic voxels (used by the pipeline) |
| `readDicom3D.m`, `dicomGE.m`, `ParseTags.m`, `ParseVols.m` | DICOM readers and tag/volume parsing |
| `OrthoDash.m` | Shows orthogonal slices of a 3D volume |
| `addborder.m` | Adds a colored border to an axes |
| `Class_Demo_Sep2_2026.m` | Class demo script |
