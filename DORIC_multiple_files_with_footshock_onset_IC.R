# Setup

library(rhdf5)

sampling_rate <- 1204.8
doric_files <- list.files(pattern = "\\.doric$")

# Signal paths
signal_path       <- "/DataAcquisition/FPConsole/Signals/Series0001/LockInAOUT01/AIN01"
time_signal_path  <- "/DataAcquisition/FPConsole/Signals/Series0001/LockInAOUT01/Time"
control_path      <- "/DataAcquisition/FPConsole/Signals/Series0001/LockInAOUT02/AIN01"
time_control_path <- "/DataAcquisition/FPConsole/Signals/Series0001/LockInAOUT02/Time"

# DIO paths
dio_time_path <- "/DataAcquisition/FPConsole/Signals/Series0001/DigitalIO/Time"
shock_path <- "/DataAcquisition/FPConsole/Signals/Series0001/DigitalIO/DIO01"
#reward_path   <- "/DataAcquisition/FPConsole/Signals/Series0001/DigitalIO/DIO02"
#press_path    <- "/DataAcquisition/FPConsole/Signals/Series0001/DigitalIO/DIO03"

# Create a folder for DORIC files
doric_folder <- file.path(getwd(), "DORIC_files")
if (!dir.exists(doric_folder)) dir.create(doric_folder)

# Loop through each .doric file 
for (file in doric_files) {
  
  base_name   <- sub("\\.doric$", "", file)
  folder_name <- file.path(getwd(), base_name)  # CSV output folder
  
  # Create output folder
  if (!dir.exists(folder_name)) dir.create(folder_name)
  
  # Move .doric file into DORIC_files
  full_path <- file.path(doric_folder, file)
  if (!file.exists(full_path)) file.rename(file, full_path)
  
  cat("Processing:", full_path, "\n")
  
  # Signal and Control
  data_signal <- h5read(full_path, signal_path)
  time_signal <- h5read(full_path, time_signal_path)
  
  df_signal <- data.frame(
    timestamps = time_signal,
    data = data_signal,
    sampling_rate = c(sampling_rate, rep(NA, length(data_signal) - 1))
  )
  df_signal[is.na(df_signal)] <- ""
  write.csv(df_signal, file.path(folder_name, paste0(base_name, "_Signal.csv")), row.names = FALSE)
  
  data_control <- h5read(full_path, control_path)
  time_control <- h5read(full_path, time_control_path)
  
  df_control <- data.frame(
    timestamps = time_control,
    data = data_control,
    sampling_rate = c(sampling_rate, rep(NA, length(data_control) - 1))
  )
  df_control[is.na(df_control)] <- ""
  write.csv(df_control, file.path(folder_name, paste0(base_name, "_Control.csv")), row.names = FALSE)
  
 

  # DIO Section (only if behavior is present)
  dio_time <- h5read(full_path, dio_time_path)
  shocks   <- h5read(full_path, shock_path)
  
  # Detect transitions from 0 -> 1 (rising edges)
  shock_onsets_idx <- which(diff(c(0, shocks)) == 1)
  shock_times <- dio_time[shock_onsets_idx]
  
  if (length(shock_times) > 0) {
    cat("Shocks detected – saving DIO timestamps...\n")
    write.csv(
      data.frame(timestamps = shock_times),
      file.path(folder_name, paste0(base_name, "_Shocks.csv")),
      row.names = FALSE
    )
  } else {
    cat("No shocks detected – skipping DIO export.\n")
  }
  
}
