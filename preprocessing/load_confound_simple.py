import os
import pandas as pd
import nibabel as nib
from nilearn.maskers import NiftiMasker
from nilearn.interfaces.fmriprep import load_confounds
from nilearn.interfaces.fmriprep import load_confounds_strategy

########################################################################################################################
# Clean functional files using denoise_strategy="simple"
########################################################################################################################

sessions = [1, 2, 3]
runs = [1, 2]
subs = ['Y01', 'Y02', 'Y03', 'Y04', 'Y05', 'Y06', 'Y07', 'Y08', 'Y09','Y10',
        'Y11', 'Y12', 'Y13', 'Y14', 'Y15', 'Y16', 'Y17','Y18', 'Y19', 'Y20',]

data_path = os.environ.get("FMRIPREP_OUTPUT", "/path/to/fmriprep_output")

for ses in sessions:
    for run in runs:
        for sub in subs:
            func_file_fmriprep = f"{data_path}/sub-{sub}/ses-{ses}/func/sub-{sub}_" \
                                 f"ses-{ses}_task-rest_run-{run}_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"
            mask = f"{data_path}/sub-{sub}/ses-{ses}/func/sub-{sub}_" \
                   f"ses-{ses}_task-rest_run-{run}_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz"

            #Extract confounds from fmripreps confounds file, using denoise_strategy="simple"  includes high_pass
            confounds, mask_empty  = load_confounds_strategy(func_file_fmriprep , denoise_strategy="simple")

            masker = NiftiMasker(mask_img=mask,memory='nilearn_cache',verbose=5, t_r=1.4, low_pass=0.1)

            time_series = masker.fit_transform(func_file_fmriprep, confounds=confounds)

            clean_img = masker.inverse_transform(time_series)

            nib.save(clean_img, f"denoised_simple/sub-{sub}_ses-{ses}_run-{run}_denoised_simple.nii.gz")

            print(f"--------------------------sub {sub} ses {ses} run {run} cleaned-------------------------------")