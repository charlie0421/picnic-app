  return (
    <section className='w-full'>
      <div className='flex justify-between items-center mb-4'>
        <div className='flex-1 flex justify-start'>
          <VoteAreaFilter
            selectedArea={selectedArea}
            onAreaChange={handleAreaChange}
          />
        </div>
        <div className='flex-1 flex justify-end'>
          <VoteStatusFilter
            selectedStatus={selectedStatus}
            onStatusChange={handleStatusChange}
          />
        </div>
      </div>
    </section>
  ) 