function test_data_loading()

    % TEST_DATA_LOADING
    % Simple test script to verify that the surface data can be loaded in MATLAB
    %
    % This script tests the data loading functionality without running the full
    % verification system.  
    fprintf('=== TESTING MATLAB DATA LOADING ===\n');
    fprintf('Testing if surface data can be loaded correctly\n\n');
    
    % Define surface data directory
    surface_data_dir = '/Users/rowanbrown/Documents/GitHub/RW_Percolation/scripts/output_3d_surfaces/surface_data';
    
    fprintf('Surface data directory: %s\n', surface_data_dir);
    
    if ~exist(surface_data_dir, 'dir')
        fprintf('✗ Directory not found!\n');
        return;
    end
    
    fprintf('✓ Directory found\n\n');
    
    % Test 1: Load comprehensive .mat file
    fprintf('Test 1: Loading comprehensive .mat file\n');
    comprehensive_file = fullfile(surface_data_dir, 'viscoelastic_surfaces_comprehensive.mat');
    
    if exist(comprehensive_file, 'file')
        try
            data = load(comprehensive_file);
            fprintf('  ✓ Comprehensive file loaded successfully\n');
            fprintf('  Available variables:\n');
            
            fields = fieldnames(data);
            for i = 1:length(fields)
                field = fields{i};
                if isstruct(data.(field))
                    fprintf('    %s: [structure]\n', field);
                else
                    fprintf('    %s: %s\n', field, mat2str(size(data.(field))));
                end
            end
            
            % Check if all required fields are present
            required_fields = {'p_grid', 'omega_grid', 'G_prime_surface', ...
                             'G_double_prime_surface', 'delta_surface', 'tan_delta_surface'};
            
            missing_fields = {};
            for i = 1:length(required_fields)
                if ~isfield(data, required_fields{i})
                    missing_fields{end+1} = required_fields{i};
                end
            end
            
            if isempty(missing_fields)
                fprintf('  ✓ All required fields present\n');
                
                % Display data info
                fprintf('  Data information:\n');
                fprintf('    p_grid: %s, range [%.4f, %.4f]\n', ...
                        mat2str(size(data.p_grid)), min(data.p_grid), max(data.p_grid));
                fprintf('    omega_grid: %s, range [%.3e, %.3e]\n', ...
                        mat2str(size(data.omega_grid)), min(data.omega_grid), max(data.omega_grid));
                fprintf('    G_prime_surface: %s\n', mat2str(size(data.G_prime_surface)));
                fprintf('    G_double_prime_surface: %s\n', mat2str(size(data.G_double_prime_surface)));
                fprintf('    delta_surface: %s\n', mat2str(size(data.delta_surface)));
                fprintf('    tan_delta_surface: %s\n', mat2str(size(data.tan_delta_surface)));
                
            else
                fprintf('  ⚠ Missing fields: %s\n', strjoin(missing_fields, ', '));
            end
            
        catch ME
            fprintf('  ✗ Error loading comprehensive file: %s\n', ME.message);
        end
    else
        fprintf('  ⚠ Comprehensive file not found\n');
    end
    
    fprintf('\n');
    
    % Test 2: Load individual .mat files
    fprintf('Test 2: Loading individual .mat files\n');
    
    individual_files = {'p_grid.mat', 'omega_grid.mat', 'G_prime_surface.mat', ...
                       'G_double_prime_surface.mat', 'delta_surface.mat', 'tan_delta_surface.mat'};
    
    for i = 1:length(individual_files)
        file_path = fullfile(surface_data_dir, individual_files{i});
        if exist(file_path, 'file')
            try
                temp_data = load(file_path);
                fprintf('  ✓ %s loaded successfully\n', individual_files{i});
            catch ME
                fprintf('  ✗ Error loading %s: %s\n', individual_files{i}, ME.message);
            end
        else
            fprintf('  ⚠ %s not found\n', individual_files{i});
        end
    end
    
    fprintf('\n');
    
    % Test 3: Test data extraction
    fprintf('Test 3: Testing data extraction and manipulation\n');
    
    try
        % Load comprehensive data
        data = load(comprehensive_file);
        
        % Extract specific p-value data
        p_target = 0.1;
        [~, p_idx] = min(abs(data.p_grid - p_target));
        p_actual = data.p_grid(p_idx);
        
        fprintf('  ✓ Extracted data for p = %.4f (actual: %.4f)\n', p_target, p_actual);
        
        % Extract G' data for this p-value
        G_prime_data = data.G_prime_surface(:, p_idx);
        fprintf('  ✓ G''(ω) data extracted: %s\n', mat2str(size(G_prime_data)));
        
        % Calculate some basic statistics
        fprintf('  ✓ G''(ω) statistics:\n');
        fprintf('    Min: %.6f, Max: %.6f, Mean: %.6f\n', ...
                min(G_prime_data), max(G_prime_data), mean(G_prime_data));
        
        fprintf('  ✓ Data extraction test successful\n');
        
    catch ME
        fprintf('  ✗ Data extraction test failed: %s\n', ME.message);
    end
    
    fprintf('\n=== DATA LOADING TEST COMPLETE ===\n');
    fprintf('If all tests passed, the MATLAB verification system should work!\n');
end

% % Main execution
% if ~exist('OCTAVE_VERSION', 'builtin')
%     % This is MATLAB
%     fprintf('Running in MATLAB environment\n');
% else
%     % This is Octave
%     fprintf('Running in Octave environment\n');
% end
% 
% % Run tests
%test_data_loading();
