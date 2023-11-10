function fig = plot_ieeg_data(data, chs, t)
% Plot iEEG data for multiple channels over time.

% Parameters:
% - data: 2D array representing iEEG data.
% - chs: Cell array of channel names corresponding to the columns in the data array.
% - t: Time linspace to plot.

% Example:
% data = rand(100, 5); % Replace with your actual iEEG data
% chs = {'Channel 1', 'Channel 2', 'Channel 3', 'Channel 4', 'Channel 5'}; % Replace with actual channel names
% t = [0:100]; % Replace with your actual time points

% Calculate medians, upper, and lower bounds
medians = median(data,1,'omitnan');
up = max(data,[],1,'omitnan') - medians;
down = medians - min(data,[],1,'omitnan');
percentile = 60;
spacing = 2 * prctile([up, down], percentile);
ticks = 0:spacing:(spacing * (size(data, 2) - 1));

% Create figure
fig = figure('Position',[0,0,1200,1000]);
ax = axes('Parent', fig);
% set(ax, 'YTick', ticks, 'YTickLabel', chs);
plot(ax, t, data - medians + ticks, 'k');

% Customize plot
xlabel('Time');
ylabel('Channels');
xlim([t(1), t(end)]);
ylim([-spacing,ticks(end)+spacing]);
yticks(ticks);
yticklabels(chs);
grid(ax, 'on');

% Set visible axis spines
ax.XAxisLocation = 'bottom';
ax.YAxisLocation = 'left';

% Display the plot
drawnow;
end


