function metrics = discrete_filling_rate(data_matrix, show_plots)
    % DISCRETE_FILLING_RATE
    % Calculates stroke volume, ejection fraction, and SV-normalized Peak 
    % Filling Rate (PFR/SV) directly from discrete 3D echo volume-time data.
    % Input:
    %   data_matrix - N x 2 matrix where col 1 = time (s), col 2 = volume (mL)
    %   show_plots  - true/false to toggle diagnostic plots (default: true)

    if nargin < 2
        show_plots = true;
    end

    %% 1. Unpack and Sort Data
    % Pull time and volume
    t = data_matrix(:, 1);
    V = data_matrix(:, 2);

    % Sort by time
    [t, sort_idx] = sort(t);
    V = V(sort_idx);

    %% 2. Discrete Volumes & Stroke Volume
    % Grab EDV and ESV directly from the min and max of the raw data points
    [EDV, idx_EDV] = max(V);
    [ESV, idx_ESV] = min(V);

    SV = EDV - ESV;
    EF = (SV / EDV) * 100;
    t_ESV = t(idx_ESV);

    %% 3. Discrete Filling Rate (Finite Differences)
    % Calculate the instantaneous rate of change between consecutive frames
    dV = diff(V);
    dt = diff(t);
    dVdt = dV ./ dt; % units: mL/s

    % Since diff() gives us N-1 values, we assign each rate to the midpoint 
    % time between the two frames it was calculated from
    t_mid = (t(1:end-1) + t(2:end)) / 2;

    % Normalize by Stroke Volume -> units: s^-1
    norm_dVdt = dVdt / SV;

    %% 4. Isolate Diastole & Find Peak Filling Rate
    % Only look at filling rates after end-systole (when the ventricle starts refilling)
    diastole_idx = find(t_mid >= t_ESV);

    [PFR, local_peak_idx] = max(dVdt(diastole_idx));
    peak_idx = diastole_idx(local_peak_idx);

    PFR_SV = norm_dVdt(peak_idx);
    t_PFR = t_mid(peak_idx);
    time_to_peak = t_PFR - t_ESV; % time from minimum volume to peak filling

    % Peak ejection rate: steepest volume fall before end-systole
    systole_idx = find(t_mid <= t_ESV);
    [PER, ejection_idx] = min(dVdt(systole_idx));
    PER = -PER; % reported as a positive rate
    t_PER = t_mid(systole_idx(ejection_idx));

    %% 5. Package Outputs
    metrics.EDV = EDV;
    metrics.ESV = ESV;
    metrics.SV = SV;
    metrics.EF = EF;
    metrics.PFR = PFR;                   % [mL/s]
    metrics.PFR_SV = PFR_SV;             % [s^-1]
    metrics.time_to_peak = time_to_peak; % [s]
    metrics.t_PFR = t_PFR;               % [s]
    metrics.PER = PER;                   % [mL/s], peak ejection rate (positive)
    metrics.t_PER = t_PER;               % [s]
    metrics.t_EDV = t(idx_EDV);          % [s]
    metrics.t_ESV = t_ESV;               % [s]

    % Save arrays in case we want to overlay multiple patients later
    metrics.t_mid = t_mid;
    metrics.dVdt = dVdt;
    metrics.norm_dVdt = norm_dVdt;

    %% 6. Diagnostic Plots
    if show_plots
        figure('Name', 'Discrete Diastolic Filling', 'Color', 'w');
        theme(gcf, 'light'); % keep black markers/lines visible when MATLAB uses the dark theme

        % Top: Discrete Volume vs. Time
        subplot(3, 1, 1);
        plot(t, V, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'DisplayName', 'Discrete Volumes');
        hold on;
        plot(t(idx_EDV), EDV, 'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r', 'DisplayName', sprintf('EDV (%.1f mL)', EDV));
        plot(t(idx_ESV), ESV, 'gs', 'MarkerSize', 9, 'MarkerFaceColor', 'g', 'DisplayName', sprintf('ESV (%.1f mL)', ESV));
        ylabel('LV Volume (mL)');
        title(sprintf('Discrete Volume-Time Curve (SV = %.1f mL, EF = %.1f%%)', SV, EF));
        legend('Location', 'best');
        grid on;

        % Bottom: Discrete SV-Normalized Filling Rate
        subplot(3, 1, 2);
        plot(t_mid, norm_dVdt, 'k.-', 'LineWidth', 1.5, 'MarkerSize', 14, 'DisplayName', '(1/SV) \DeltaV/\Deltat');
        hold on;
        plot(t_PFR, PFR_SV, 'r^', 'MarkerSize', 9, 'MarkerFaceColor', 'r', ...
             'DisplayName', sprintf('PFR/SV = %.2f s^{-1}', PFR_SV));
        xline(t_ESV, '--', 'Color', [0.5 0.5 0.5], 'DisplayName', 'End-Systole (ESV)');
        yline(0, 'k:', 'HandleVisibility', 'off');
        xlabel('Time (s)');
        ylabel('Normalized Filling Rate (s^{-1})');
        title(sprintf('Discrete Normalized Filling Rate (PFR = %.1f mL/s)', PFR));
        legend('Location', 'best');
        grid on;

        % Bottom: Discrete Absolute Filling Rate (not normalized)
        subplot(3, 1, 3);
        plot(t_mid, dVdt, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 14, 'DisplayName', '\DeltaV/\Deltat');
        hold on;
        plot(t_PFR, PFR, 'r^', 'MarkerSize', 9, 'MarkerFaceColor', 'r', ...
             'DisplayName', sprintf('PFR = %.1f mL/s', PFR));
        xline(t_ESV, '--', 'Color', [0.5 0.5 0.5], 'DisplayName', 'End-Systole (ESV)');
        yline(0, 'k:', 'HandleVisibility', 'off');
        xlabel('Time (s)');
        ylabel('Filling Rate (mL/s)');
        title(sprintf('Discrete Absolute Filling Rate (PFR = %.1f mL/s)', PFR));
        legend('Location', 'best');
        grid on;
    end
end