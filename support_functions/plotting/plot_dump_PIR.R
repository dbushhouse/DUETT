plot_data <- function(data_vector, event_locations, concurrent_events, n_col, event_colors = c("green", "blue"), ylim = c(0,max(data_vector, na.rm = T)), mar = c(4,4,3,3), xaxis_offset = 0, xaxis_interval = 5, dot_color = "grey40", disable_title = F, first_plot = T) {
  
  num_points = length(data_vector)
  
  # set graphing parameters
  par(mar = mar)
  xlim = c(0, num_points)
  
  # check and set indices if swing_events are specified
  upswing_indices = which(event_locations == 1 | event_locations == 3 | event_locations == -1.5)
  downswing_indices = which(event_locations == -1 | event_locations == -3 | event_locations == 1.5)
  ramp_indices = list(which(event_locations == 2 | event_locations == 3 | event_locations == 1.5), which(event_locations == -2 | event_locations == -3 | event_locations == -1.5))
  
  nonevent_data = data_vector
  if (length(c(upswing_indices, downswing_indices)) > 0) {
    nonevent_data[c(upswing_indices, downswing_indices)] = NA
  }
  
  ifelse(disable_title, main <- "", main <- paste("Columns", n_col))
  
  # lay down first plot stuff
  if (first_plot) {
    plot(0, type = "n", main = main, pch = 23, xaxt = "n", xlab = "", ylab = "", xlim = xlim, ylim = ylim)
    axis_info = c(1, seq(1 + (abs(xaxis_interval) - 1) * sign(xaxis_interval), num_points, by = xaxis_interval))
    axis(1, at=axis_info, labels = axis_info + xaxis_offset)
  }
  par(new = T)
  # plot smoothed data alongside original data
  plot(nonevent_data, pch = 23, axes = F, bty = "n", main = "", xlab = "", ylab = "", xlim = xlim, ylim = ylim, col = dot_color)

  par(new = T)
  plot(x = upswing_indices, y = data_vector[upswing_indices], pch = 23, axes = F, bty = "n", main = "", xlab = "", ylab = "", xlim = xlim, ylim = ylim, col = event_colors[[1]], lwd = 2, cex = 1.3)
  par(new = T)
  plot(x = downswing_indices, y = data_vector[downswing_indices], pch = 23, axes = F, bty = "n", main = "", xlab = "", ylab = "", xlim = xlim, ylim = ylim, col = event_colors[[2]], lwd = 2, cex = 1.3)
  
  # ramp plotting
  for (n_ramp in 1:2) {
    if (length(ramp_indices[[n_ramp]]) > 0) {
      ramp_ends = which(c(diff(ramp_indices[[n_ramp]]) != 1, T))
      
      ramp_start = 1
      for (ramp_end in ramp_ends) {
        par(new = T)
        lm_obj = lm(data_vector[ramp_indices[[n_ramp]][ramp_start:ramp_end]] ~ ramp_indices[[n_ramp]][ramp_start:ramp_end])
        
        plot(x = ramp_indices[[n_ramp]][ramp_start:ramp_end], y = lm_obj$fitted.values, pch = 23, axes = F, bty = "n", main = "", xlab = "", ylab = "", xlim = xlim, ylim = ylim, col = event_colors[[n_ramp]], lwd = 6, cex = 1.3, type = "l")
        ramp_start = ramp_end + 1
      }
    }
  }
  
  # create concurrent lines
  if (n_col %in% concurrent_events[, c("col1", "col2")]) {
    
    source("support_functions/color_to_hex.R")
    line_color = color_to_hex("forestgreen", 0)
    
    relevant_rows = which(concurrent_events[, "col1"] == n_col | concurrent_events[, "col2"] == n_col)
    for (n_relevant in relevant_rows) {
      
      if (concurrent_events[[n_relevant, "col1"]] == n_col) {
        x_point = concurrent_events[[n_relevant, "row1"]]
        lines(rep(x_point, 2), ylim, lty = 3, col = line_color)
      }
      
      if (concurrent_events[[n_relevant, "col2"]] == n_col) {
        x_point = concurrent_events[[n_relevant, "row2"]]
        lines(rep(x_point, 2), ylim, lty = 3, col = line_color)
      }
    }
  }
}

########################################################################################

plot_PIR_cutoffs <- function(event_details, event_locations, n_col = NULL, cutoffs, event_colors = c("green", "blue")) {
  
  num_points = nrow(event_details$P_values)
  values_list = list(event_details$P_values[,n_col,drop = F], event_details$I_values[,n_col, drop = F], event_details$R_values[,n_col, drop = F])
  
  par(mar = c(2,4,2,3))
  
  xlim = c(0, num_points)
  ylim = c(-1,1)
  PIR_letters = c("P","I","R")
  axis_side = c(2,2,4)
  line_info = c(1, -0.9, -0.9)
  mtext_line = c(1.8, -0.1, -0.1)
  pch_info = c(19, 22, 12)
  plot_type = c("p", "p", "p")
  
  ############################################
  
  plot(1, type = "n", xlim = xlim, ylim = ylim, xaxt = "n", yaxt = "n", xlab = "", ylab = "")
  axis_info = round(seq(0,num_points,length.out=10))
  axis(1, at=axis_info, labels = axis_info)
  par(new = T)
  for (n_PIR in 1:3) {
    
    # find event_indices for up/down/non-events
    upswing_indices = which(event_locations %in% c(1,3))
    downswing_indices = which(event_locations %in% c(-3,-1))
    
    nonevent_indices = 1:num_points
    if (length(c(upswing_indices, downswing_indices)) > 0) {
      nonevent_indices[c(upswing_indices, downswing_indices)] = NA
    }
    
    # normalize between -1 and 1
    if (n_PIR == 1) {
      PIR_range = c(-(1-(1 / (1+cutoffs$R))) * 2, cutoffs$R * 2)
      temp = values_list[[n_PIR]]
      temp[(temp > 0) %in% T] = temp[(temp > 0) %in% T] / PIR_range[[2]]
      temp[(temp < 0) %in% T] = temp[(temp < 0) %in% T] / -PIR_range[[1]]
    } else {
      PIR_range = c(-2 * cutoffs[[n_PIR]], 2 * cutoffs[[n_PIR]])
      temp = values_list[[n_PIR]] / PIR_range[[2]]
    }
    
    # first plot non values
    plot(x = nonevent_indices, y = temp[nonevent_indices], xlim = xlim, ylim = ylim, pch = pch_info[[n_PIR]], axes = F, bty = "n", col = "grey60", xlab = "", ylab = "")
    par(new = T)
    plot(x = upswing_indices, y = temp[upswing_indices], xlim = xlim, ylim = ylim, pch = pch_info[[n_PIR]], axes = F, bty = "n", col = event_colors[[1]], xlab = "", ylab = "", type = plot_type[[n_PIR]])
    par(new = T)
    plot(x = downswing_indices, y = temp[downswing_indices], xlim = xlim, ylim = ylim, pch = pch_info[[n_PIR]], axes = F, bty = "n", col = event_colors[[2]], xlab = "", ylab = "", type = plot_type[[n_PIR]])
    
    # put in axis and axis label
    axis(side = axis_side[[n_PIR]], at = seq(-1,1, by = 0.5), labels = round(c(PIR_range[[1]], PIR_range[[1]]/2, 0, PIR_range[[2]]/2, PIR_range[[2]]), digits = 2), line = line_info[[n_PIR]], tick = F)
    mtext(paste(PIR_letters[[n_PIR]], "change"), side = axis_side[[n_PIR]], line = mtext_line[[n_PIR]] + 1)
    par(new = T)
    
  }
  
  # put in lines
  lines(c(0, num_points), c(0,0))
  lines(c(0, num_points), rep(-0.5, 2), lty = 2)
  lines(c(0, num_points), rep(0.5, 2), lty = 2)
  text(0, 0.5, labels = "upswing", adj = c(0, -1))
  text(0, -0.5, labels = "downswing", adj = c(0, 1.5))
  
}

########################################################################################

make_col_detail_plots <- function(col_group, data_mat, location_list, event_details, concurrent_events, event_colors, cutoffs, ylim = c(0, 1), xaxis_offset = 0, xaxis_interval = 5) {
  # this function assumes that data_mat is a list
  
  par(mfrow = c(4,4))
  for (n_col in col_group) {
    first_plot = T
    for (n_file in 1:length(data_mat)) {
      # check for non-NAs
      if (sum(is.na(data_mat[[n_file]][,n_col, drop = F])) != nrow(data_mat[[n_file]])) {
        plot_data(data_mat[[n_file]][,n_col, drop = F], location_list[,n_col, drop = F], concurrent_events, n_col, event_colors = event_colors, ylim = ylim, xaxis_offset = xaxis_offset, xaxis_interval = xaxis_interval, first_plot = first_plot)
        first_plot = F
      }
    }
  }
}

