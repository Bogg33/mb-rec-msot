classdef Probe
    
    properties
        probeId;
        includeEir;
        includeIndivEir;
        detector;
        DAC;
        membrane;
        coupling;
    end
    properties (Constant)
        eirLength = 79;
    end
    
    methods (Access=public)
        function probe = Probe(probe_id, include_eir, include_indiv_eir, speed_of_sound_coupling)
            if nargin < 4
                speed_of_sound_coupling = [];
            end
            
            % assign general parameters
            probe.probeId = probe_id;
            probe.includeEir = include_eir;
            probe.includeIndivEir = include_indiv_eir;
            
            % assign probe (coupling & detector array) parameters & membrane
            probe = probe.get_probe_properties(probe_id);
            
            % assign specified coupling SoS, if desired
            if ~isempty(speed_of_sound_coupling)
                probe.coupling.speedOfSound = speed_of_sound_coupling;
            end
            
            % Load EIR of detector array
            if probe.includeEir
                EIR_file = which(['EIR_' probe.probeId '.mat']);
                if probe.includeIndivEir
                    mat_file_var = who('-file',EIR_file,'EIR_indiv_mat');
                    if ~isempty(mat_file_var)
                        load(EIR_file,mat_file_var{1});
                        probe.detector.EIR = EIR_indiv_mat;
                    else
                        warning('No individual EIR for probe %s available. Average EIR used instead.',probe.probeId);
                        probe.includeIndivEir = false;
                        load(EIR_file, 'EIR');
                        probe.detector.EIR = EIR;
                    end
                else
                    load(EIR_file, 'EIR');
                    probe.detector.EIR = EIR;
                end
                
                % Check correct sampling of EIR
                assert(size(probe.detector.EIR,1) == 79,...
                    'Length of EIR is defined to be 79 which is not the case. Please adjust the provided EIR for probe %s.',probe.probeId)
            else
                probe.detector.EIR = zeros(probe.eirLength,1);
                probe.detector.EIR(floor(probe.eirLength/2)+1,1) = 1;
            end
        end
        
        function visualize(probe)
            figure;
            
            % Plot transducer array
            x_detector_max = max(abs(probe.detector.xPositionsOfTransducers));
            z_detector_max = max(abs(probe.detector.zPositionsOfTransducers));
            plot(probe.detector.xPositionsOfTransducers,probe.detector.zPositionsOfTransducers,'k.');
           
            % Plot membrane
            if isa(probe.membrane,'function_handle')
                x_membrane = linspace(-1.1*x_detector_max,1.1*x_detector_max,500);
                hold on;
                plot(x_membrane,probe.membrane(x_membrane),'b');
                hold off;
            end
            
            % Set graphics accordingly
            axis equal;
            pbaspect([1 1 1]);
            xlim([-1.1*x_detector_max, 1.1*x_detector_max]);
            ylim([-1.1*z_detector_max, 1.1*z_detector_max]);
            set(gca,'FontSize', 9);
            view([0 -90]);
        end
        
        function probe = set_custom_membrane_model(probe,custom_membrane_model)
            if isa(custom_membrane_model,'function_handle')
                probe.membrane = custom_membrane_model;
            else
                error('Custom membrane model must be function handle.');
            end
        end      
    end
    
    methods (Access=private)
        % Load properties of specific probe
        function probe = get_probe_properties(probe, probeId)
            
            if strcmpi(probeId ,'L11-5v_resampled')
                % coupling medium
                probe.coupling.medium = 'heavy water';
                probe.coupling.speedOfSound = 1397;
                
                % membrane
                probe.membrane = probe.load_membrane_model('horizontal_example');
                
                % detector array
                probe.detector.numOfTransducers = 128;                      % [1] number of detector elements in array
                probe.detector.radius = 0;                              % [m] imaging plane radius of array
                probe.detector.angularCoverage = 0;                       % [deg] angular coverage of detector elements in semi-circle with radius=radius
                angular_offset = (180-probe.detector.angularCoverage)/2;    % [deg] angular offset from 0 to first detector element
                angles = ( angular_offset : probe.detector.angularCoverage/(probe.detector.numOfTransducers-1) : (180-angular_offset) ) * pi/180; % [rad] angles of detectors
                probe.detector.xPositionsOfTransducers = 0.01905:-0.0003:-0.01905;     % [m] x-coordinates of detectors
                probe.detector.zPositionsOfTransducers = zeros(1,128);  % [m] z-coordinates of detectors
                                
                % single detector transducer (all values here made-up placeholders)
                probe.detector.elevationRadiusOfSingleTransducer = 18e-3;   % [m] elevation radius of single detector curvature
                probe.detector.heightofSingleTransducer = 5e-3;            % [m] height of single detector
                probe.detector.pitchOfTransducers = 0.3e-3;                 % [m] pitch (width+seperation) of single detector
                probe.detector.seperationBetweenTransducers = 0.03e-3;       % [m] element seperation
                 
                % DAC
                probe.DAC.numRecordedSamplesPerTransducer = 1408;    % total number of recorded time samples per transducer per scan
                probe.DAC.delayBeforeRecording = 0;                % time samples delaying start of recording by DAC
                probe.DAC.frequency = 31.25e6;                           % [Hz] sampling frequency of DAC

            else
                error('Unknown device id.');
            end
        end
        
        % Load membrane model according to probe specification
        function membrane_model = load_membrane_model(~,name)
            if strcmp(name,'horizontal_example')
                membrane_model = @membrane_model_horizontal_example;
            elseif strcmp(name,'none')
                membrane_model = 'none';
            else
                error(['Unknown membrane model "' name '".'])
            end
        end
        
    end
end

function z = membrane_model_horizontal_example(x)
    % y-coordinates of membrane
    z = -1*0.01*ones(size(x));
end
