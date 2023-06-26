function p0_rec = backproject_waveeq(...
    sigMat,...
    fov_x,...
    fov_y,...
    x_position, ...
    z_position, ...
    speed_of_sound,...
    sampling_frequency,...
    cropped_or_unrecorded_signals_at_sinogram_start,...
    angular_coverage,...
    detector_radius,...
    psf,...
    K)

% Derive required properties from input parameters
dt = 1/sampling_frequency;
number_of_samples = size(sigMat, 1);
number_of_transducers = size(sigMat, 2);
% angular_offset = (180 - angular_coverage) / 2;
% transducer_angles = -(angular_offset : angular_coverage/(number_of_transducers-1) : (180-angular_offset) ) * pi/180;  
aquisition_times_in_samples = (1:number_of_samples) + cropped_or_unrecorded_signals_at_sinogram_start;
aquisition_times_in_seconds = aquisition_times_in_samples * dt;


% Convert sigMat to radial integrals
sigMat = cumtrapz(aquisition_times_in_seconds, sigMat/speed_of_sound, 1)...
   ./ repmat(aquisition_times_in_seconds, [number_of_transducers, 1])';

% Apply prefilter
sigMat = convn(sigMat, psf, 'same') / sum(psf(:));

p0_rec = zeros(size(fov_x,1), size(fov_x,2), size(sigMat,3));
for wavelength = 1:size(sigMat,3)
    p0_rec_x = zeros(size(fov_x));
    p0_rec_y = zeros(size(fov_x));
    sigMat_wl = K(aquisition_times_in_samples, aquisition_times_in_samples) * sigMat(:,:,wavelength) * dt;
  
    for p = 1:number_of_transducers
        % Calculate time needed for propagation from every pixel to detector and convert to indices in the time array (nearest interpolation)
        % Here i removed dependencies from angular coverage and radius
        
        distance = sqrt(abs((fov_x(:)- x_position(p))).^2 + abs((fov_y(:)- z_position(p))).^2);
        
        T = round((distance/speed_of_sound - aquisition_times_in_seconds(1))...
            *sampling_frequency + 1);



%         T = round((...
%                 sqrt(abs(fov_x(:)-cos(transducer_angles(p))*detector_radius).^2 + abs(fov_y(:)-sin(transducer_angles(p))*detector_radius).^2)...
%                 / speed_of_sound...
%                 - aquisition_times_in_seconds(1)...
%             )*sampling_frequency + 1 ...
%             );



        % add all values in sigMat as indexed by T
        p0_rec_x(:) = p0_rec_x(:) + sigMat_wl(T,p)*dt*speed_of_sound;
        p0_rec_y(:) = p0_rec_y(:)' + sigMat_wl(T,p)'*dt*speed_of_sound;
%         p0_rec_x(:) = p0_rec_x(:) + sigMat_wl(T,p).*cos(transducer_angles(p))*dt*speed_of_sound;
%         p0_rec_y(:) = p0_rec_y(:) + sigMat_wl(T,p).*sin(transducer_angles(p))*dt*speed_of_sound;
    end

    p0_rec(:,:,wavelength) = fliplr(divergence(fov_x, fov_y, p0_rec_x, p0_rec_y));
end
