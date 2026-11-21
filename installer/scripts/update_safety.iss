var
  IsUpgrade: Boolean;
  VerifiedBackupPath: String;

function DataRoot: String;
begin
  Result := ExpandConstant('{localappdata}\{#ProductName}\Data');
end;

function SettingsRoot: String;
begin
  Result := ExpandConstant('{userappdata}\{#ProductName}\{#ProductName}');
end;

procedure CopyVerifiedTree(const SourceDir, DestinationDir: String);
var
  Entry: TFindRec;
  SourceFile, DestinationFile: String;
begin
  if not DirExists(SourceDir) then Exit;
  if not ForceDirectories(DestinationDir) then
    RaiseException('Cannot create the backup folder: ' + DestinationDir);
  if FindFirst(AddBackslash(SourceDir) + '*', Entry) then
  begin
    try
      repeat
        if (Entry.Name <> '.') and (Entry.Name <> '..') then
        begin
          SourceFile := AddBackslash(SourceDir) + Entry.Name;
          DestinationFile := AddBackslash(DestinationDir) + Entry.Name;
          if (Entry.Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0 then
            RaiseException('A linked data folder needs a manual backup: ' + SourceFile);
          if (Entry.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
            CopyVerifiedTree(SourceFile, DestinationFile)
          else
          begin
            if not CopyFile(SourceFile, DestinationFile, True) then
              RaiseException('Cannot back up a data file: ' + SourceFile);
            if GetSHA256OfFile(SourceFile) <> GetSHA256OfFile(DestinationFile) then
              RaiseException('Backup verification failed: ' + SourceFile);
          end;
        end;
      until not FindNext(Entry);
    finally
      FindClose(Entry);
    end;
  end
  else
    RaiseException('Cannot read the backup source folder: ' + SourceDir);
end;

function IsWithin(const DirectoryName, ParentName: String): Boolean;
var
  DirectoryPath, ParentPath: String;
begin
  DirectoryPath := AddBackslash(ExpandFileName(DirectoryName));
  ParentPath := AddBackslash(ExpandFileName(ParentName));
  Result := CompareText(Copy(DirectoryPath, 1, Length(ParentPath)), ParentPath) = 0;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  BackupRoot, Candidate, Manifest: String;
  Suffix: Integer;
begin
  Result := '';
  VerifiedBackupPath := '';
  if FindWindowByWindowName('{#ProductName}') <> 0 then
  begin
    Result := 'Close {#ProductName}, then click Retry. Your records must be closed before Setup creates the update backup.';
    Exit;
  end;
  BackupRoot := ExpandConstant('{localappdata}\{#ProductName}\Backups');
  if IsWithin(ExpandConstant('{app}'), DataRoot) or
     IsWithin(DataRoot, ExpandConstant('{app}')) or
     IsWithin(ExpandConstant('{app}'), BackupRoot) or
     IsWithin(ExpandConstant('{app}'), SettingsRoot) then
  begin
    Result := 'Choose a program installation folder outside the data, settings and backup folders.';
    Exit;
  end;
  if not DirExists(DataRoot) and not DirExists(SettingsRoot) then Exit;
  try
    Candidate := AddBackslash(BackupRoot) + 'before-{#AppVersion}-' +
      GetDateTimeString('yyyymmdd-hhnnss', '-', ':');
    Suffix := 0;
    while DirExists(Candidate + '-' + IntToStr(Suffix)) do Suffix := Suffix + 1;
    Candidate := Candidate + '-' + IntToStr(Suffix);
    if not ForceDirectories(Candidate) then
      RaiseException('The update backup folder could not be created.');
    CopyVerifiedTree(DataRoot, AddBackslash(Candidate) + 'Data');
    CopyVerifiedTree(SettingsRoot, AddBackslash(Candidate) + 'Settings');
    Manifest := '{#ProductName} pre-update backup' + #13#10 +
      'Target version: {#AppVersion}' + #13#10 +
      'Data folder: ' + DataRoot + #13#10 +
      'Settings folder: ' + SettingsRoot + #13#10 +
      'Every copied file was verified with SHA-256.' + #13#10;
    if not SaveStringToFile(AddBackslash(Candidate) + 'backup-complete.txt', Manifest, False) then
      RaiseException('The backup completion record could not be saved.');
    VerifiedBackupPath := Candidate;
    Log('Verified pre-update backup: ' + VerifiedBackupPath);
  except
    Result := 'Setup stopped because the data backup could not be completed. No application files have been replaced.';
    Result := Result + #13#10 + GetExceptionMessage;
  end;
end;

procedure InitializeWizard;
var
  InstalledVersion: String;
begin
  IsUpgrade := RegQueryStringValue(HKCU,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#ProductId}_is1',
    'DisplayVersion', InstalledVersion);
  if IsUpgrade then
  begin
    WizardForm.Caption := '{#ProductName} Update';
    WizardForm.WelcomeLabel1.Caption := 'Update {#ProductName} to {#AppVersion}';
    WizardForm.WelcomeLabel2.Caption :=
      'Setup will update your existing installation and keep your business records.' + #13#10 + #13#10 +
      'A verified backup of your data and settings will be created before any application files are replaced.' + #13#10 + #13#10 +
      'Close {#ProductName} before continuing.';
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if IsUpgrade and (CurPageID = wpReady) then
    WizardForm.NextButton.Caption := '&Update';
  if IsUpgrade and (CurPageID = wpInstalling) then
    WizardForm.PageNameLabel.Caption := 'Updating {#ProductName}';
  if (CurPageID = wpFinished) and (VerifiedBackupPath <> '') then
    WizardForm.FinishedLabel.Caption :=
      '{#ProductName} {#AppVersion} is ready. Your existing business data has been kept.' + #13#10 +
      'Pre-update backup:' + #13#10 + VerifiedBackupPath;
end;
